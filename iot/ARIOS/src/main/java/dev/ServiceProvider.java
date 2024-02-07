package dev;

import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;

public class ServiceProvider extends Thread {

    private List<NetService> services;
    private int port;
    private String type = "_http._tcp";
    private String serviceFilePath;
    private File serviceFile;

    private ServerSocket server;
    private Socket socket;

    private DataValidator validator = new DataValidator();

    private boolean running = true;

    /**
     * Class constructor.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     *
     * @param pServices The list of provided {@link NetService}s.
     * @param path      The absolute path of the Avahi service file.
     * @param port      The port to be used for the {@link ServerSocket}.
     */
    public ServiceProvider(List<NetService> pServices, String path, int port) {
        this.services = pServices;
        this.serviceFilePath = path;
        this.serviceFile = new File(this.serviceFilePath);
        this.port = port;
    }

    /**
     * Code to run after thread gets started.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     */
    @Override
    public void run() {
        this.running = true;
        startSocket(false);
    }

    /**
     * Setup and start server socket.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     *
     * @param restart   Indicates whether the function is called initially or after restart of the {@link ServerSocket}.
     */
    private void startSocket(boolean restart) {
        try {
            this.server = new ServerSocket(this.port);
            if(!restart) {
                this.port = this.server.getLocalPort();
                checkServiceFile();

                System.out.println("Using port " + this.port + ".");
            }

            this.socket = server.accept();

            System.out.println(this.socket.getInetAddress().toString().substring(1) + " has connected.");

            try (BufferedReader br = new BufferedReader(new InputStreamReader(this.socket.getInputStream()))){
                while(true) {
                    // wait for input and process it
                    String data = br.readLine();

                    // Input should be in following format: <SERVICE_TYPE>=<value>
                    String[] splitUpData = data.split("=");

                    if(this.validator.validData(splitUpData, this)) {
                        // retrieve service by serviceType (splitUpData[0]) and set its value (splitUpData[1])
                        for (NetService service : this.services) {
                            if (service.getType().toString().equals(splitUpData[0])) {

                                String old = service.getValue();

                                // change value
                                service.setValue(splitUpData[1]);

                                // update service file
                                updateService(service);

                                // print info
                                System.out.println("[" + this.socket.getInetAddress().toString().substring(1) + "]: " +
                                        "Changed value of Service " + service.getType() + " to " + splitUpData[1] + " (old: " + old + ").");

                                break;
                            }
                        }
                    }
                }
            }
            // device disconnected
            catch (NullPointerException e) {
                System.out.println(this.socket.getInetAddress().toString().substring(1) + " has disconnected.");
                this.server.close();
                startSocket(true);
            } catch (SocketException e) {
                System.out.println(this.socket.getInetAddress().toString().substring(1) + " has disconnected.");
                this.server.close();
                startSocket(true);
            }
        } catch(IOException e) {
            e.printStackTrace();
            toggleRunningRecord(false);
        }
    }

    /**
     * Check service file's existence and/or correct current content.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     */
    private void checkServiceFile() {
        try {
            // file exists
            if(serviceFile.isFile()) {
                validateServiceFile();
            }
            // path is not a directory but doesn't exist yet
            else if(!serviceFile.isDirectory()) {
                serviceFile.createNewFile();
                initServiceFile();
            }
            // invalid file/path
            else {
                return;
            }
        } catch (IOException e) {
            System.err.println("An error occurred while checking service file @ " + this.serviceFilePath);
            this.running = false;
            System.exit(0);
        }
    }

    /**
     * Initialize service file's content.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     */
    private void initServiceFile() {
        try {
            // CREATING CONTENT AND WRITING TO FILE
            String fileContent =
                    "<?xml version=\"1.0\" standalone='no'?><!--*-nxml-*-->\n" +
                            "<!DOCTYPE service-group SYSTEM \"avahi-service.dtd\">\n\n" +
                            "<service-group>\n\n" +
                            "  <name replace-wildcards=\"yes\">%h</name>\n\n" +
                            "  <service>\n" +
                            "    <type>" + this.type + "</type>\n" +
                            "    <port>" + this.port + "</port>\n" +
                            createTxtRecords() +
                            "  </service>\n\n" +
                            "</service-group>\n";

            FileWriter fw = new FileWriter(this.serviceFile);
            fw.write(fileContent);
            fw.flush();
            fw.close();
        } catch (IOException e) {
            System.err.println("An error occurred while writing to service file @" + this.serviceFilePath);
            this.running = false;
            System.exit(0);
        }
    }

    /**
     * Update txt-records (except 'running') and port.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     */
    public void validateServiceFile() {
        try {
            synchronized (this.serviceFile) {
                List<String> lines = Files.readAllLines(Paths.get(this.serviceFilePath));
                List<String> txt_records = new ArrayList<>();

                for (String line: lines) {

                    if(line.contains("<port>") && !line.contains(("<txt-record>textfield="))) {
                        lines.set(lines.indexOf(line), "    <port>" + this.port + "</port>");
                    }

                    // check for old txt-record usage (except running)
                    if (line.contains("<txt-record>") && !line.contains("<txt-record>running")) {
                        txt_records.add(line);
                    }

                    if(line.contains(("txt-record>running"))) {
                        lines.set(lines.indexOf(line), "    <txt-record>running=" + true + "</txt-record>\"");
                    }
                }

                lines = checkOldRecordUsage(lines, txt_records);

                Files.write(Paths.get(this.serviceFilePath), lines);
            }
        } catch (IOException e) {
            System.err.println("An error occurred while validating service file @ " + this.serviceFilePath);
            this.running = false;
            System.exit(0);
        }
    }

    /**
     * Toggle running &lt;txt-record&gt; in Avahi service file to running.
     * @param running       Boolean value to set running &lt;txt-record&gt; to.
     */
    public void toggleRunningRecord(boolean running) {
        try {
            synchronized (this.serviceFile) {
                List<String> lines = Files.readAllLines(Paths.get(this.serviceFilePath));

                for (String line : lines) {
                    if (line.contains("<txt-record>running")) {
                        lines.set(lines.indexOf(line), "    <txt-record>running=" + running + "</txt-record>");
                    }
                }

                Files.write(Paths.get(this.serviceFilePath), lines);
            }

            if(!running) { closeServer(); }
        } catch (IOException e) {
            System.err.println("An error occurred while toggling running entry @ " + this.serviceFilePath);
            this.running = false;
            System.exit(0);
        }
    }

    /**
     * Create &lt;txt-record&gt;s used in service file.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     *
     * @return The {@link String} containing all &lt;txt-record&gt;-tags.
     */
    private String createTxtRecords() {
        String txt_records = "";

        txt_records += "    <txt-record>running=true</txt-record>\n";

        for (NetService service: this.services) {
            txt_records += "    <txt-record>" + service.getType().toString().toLowerCase() + "=" + service.getValue() + "</txt-record>\n";
        }

        return txt_records;
    }

    /**
     * Update {@link NetService} record in service file.
     * @param service   The {@link NetService} to update.
     */
    private void updateService(NetService service) {
        try {
            synchronized (this.serviceFile) {
                List<String> lines = Files.readAllLines(Paths.get(this.serviceFilePath));

                for (String line: lines) {
                    if(line.contains("<txt-record>" + service.getType().toString().toLowerCase())) {
                        lines.set(lines.indexOf(line), "    <txt-record>" + service.getType().toString().toLowerCase() + "=" + service.getValue() + "</txt-record>");
                    }
                }

                Files.write(Paths.get(this.serviceFilePath), lines);
            }
        } catch (IOException e) {
            System.err.println("An error occurred while updating service " + service.getType().toString() + " @ " + this.serviceFilePath);
            this.running = false;
            System.exit(0);
        }
    }

    /**
     * Checks service-file for old &lt;txt-records&gt; usage. Removes old records and adds new ones.
     * @param lines         The content of the service-file.
     * @param records       The &lt;txt-record&gt;s contained in service-file.
     * @return  The new service-file with the old records removed and new ones added.
     */
    private List<String> checkOldRecordUsage(List<String> lines, List<String> records) {
        List<NetService> tServices = deepCopy(this.services);

        // we cannot use "normal" foreach loop because removing inside the loop triggers ConcurrentModificationException
        for (Iterator<NetService> ns_iterator = tServices.iterator(); ns_iterator.hasNext();) {
            NetService ns = ns_iterator.next();
            for (Iterator<String> record_iterator = records.iterator(); record_iterator.hasNext();) {
                String record = record_iterator.next();
                // NetService is already in file. Use value from file.
                if (record.toLowerCase().contains(ns.getType().toString().toLowerCase())) {
                    record_iterator.remove();
                    ns_iterator.remove();
                }
            }
        }
        // records now contains records which are old and not used anymore.
        // tServices now contains NetServices which are new and needs to be added to file.

        // removing old/unused records
        for(String record: records) {
            lines.remove(lines.indexOf(record));
        }

        // adding new NetServices
        for(NetService ns: tServices) {
            int lastTxtRecordIndex = getLastTxtRecordIndex(lines);
            String entry = "    <txt-record>" + ns.getType().toString().toLowerCase() + "=" + ns.getValue() + "</txt-record>";
            lines.add(lastTxtRecordIndex + 1, entry);
        }

        return lines;
    }

    /**
     * Returns line index of last &lt;txt-record&gt; in the service-file.
     * @param lines     The content of the service-file.
     * @return  The index of the last &lt;txt-record&gt;.
     */
    private int getLastTxtRecordIndex(List<String> lines) {
        String lastTxtRecord = "";
        for(String line: lines) {
            if ((line.contains("<txt-record>") && !line.contains("textfield")) || line.contains("<txt-record>textfield")) {
                lastTxtRecord = line;
            }
        }

        // no txt-records in file, return index of port-line
        if(lastTxtRecord.equals("")) {
            for(String line: lines) {
                if (line.contains("<port>") && !line.contains("textfield")) {
                    return lines.indexOf(line);
                }
            }
            // should not happen. file should always contain <port>-entry.
            return -1;
        }
        else { return lines.indexOf(lastTxtRecord); }

    }

    /**
     * Send closing message to remote Socket and close {@link ServerSocket}.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     */
    public void closeServer() {
        try {
            try (BufferedWriter bos = new BufferedWriter(new OutputStreamWriter(this.socket.getOutputStream()))){
                bos.write("Closing connection!");
            }
            this.server.close();
        } catch (IOException e) {
            // no active connection
            // exception can be ignored.
        } catch (NullPointerException e) {
            // no active connection
            // exception can be ignored.
        }
    }

    /**
     * Make a deep-copy of given {@link NetService}-{@link List}.
     * @param list      The {@link NetService}-{@link List} to make a deep-copy of.
     * @return  A deep-copy of list.
     */
    private List<NetService> deepCopy(List<NetService> list) {
        List<NetService> copy = new ArrayList<>(list.size());
        for(NetService item: list) { copy.add(item); }
        return copy;
    }

    /**
     * Prints serviceFile content.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     */
    private void printFile() {
        try {
            List<String> lines = Files.readAllLines(Paths.get(this.serviceFilePath));
            for (String line: lines) {
                System.out.println(line);
            }
        } catch (IOException e) {
            System.err.println("An error occurred while reading service file @" + this.serviceFilePath);
            toggleRunningRecord(false);
        }
    }

    /**
     * Returns the {@link Socket}-object.
     * @return  The {@link Socket}-object.
     */
    public Socket getSocket() { return this.socket; }

    public boolean getRunning() { return this.running; }
}
