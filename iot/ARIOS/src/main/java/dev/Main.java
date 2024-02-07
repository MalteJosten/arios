package dev;

import java.io.IOException;
import java.net.DatagramSocket;
import java.net.ServerSocket;
import java.util.ArrayList;
import java.util.List;

public class Main {

    private static ServiceProvider provider;
    private static List<NetService> services;
    private static String path;
    private static int port;

    private static boolean initializedParams = false;

    /**
     * Method to be run on application launch. Takes console-input, handles application-shutdown and initiates {@link ServiceProvider}.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     *
     * @param args  The arguments passed in by console input.
     */
    public static void main(String[] args) {

        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            if(initializedParams && provider.getRunning()) {
                provider.toggleRunningRecord(false);
            }
        }, "Shutdown-Thread"));

        if (args.length == 0) {
            commandPrompt(promptEnum.NO_PARAMETERS, "");
        } else {
            extractParams(args);
        }
    }

    /**
     * Extracting parameters from input array.
     * @param input The input array.
     */
    private static void extractParams(String[] input) {
        // checking for --help command
        for (String s: input) {
            if (s.equals("--help")) {
                commandPrompt(promptEnum.HELP, "");
            }
        }

        // checking file path
        if (!input[0].contains(".service")) { commandPrompt(promptEnum.NO_FILE, ""); }
        else { path = input[0]; }

        // checking port
        try {
            if (!checkPortAvailability(Integer.parseInt(input[1]))) {
                commandPrompt(promptEnum.PORT_UNAVAILABLE, "");
            }
        } catch (NumberFormatException e) {
            commandPrompt(promptEnum.PORT_FORMAT, "");
        }

        // checking elements
        if(input.length <= 2) { commandPrompt(promptEnum.NO_SERVICES, ""); }

        String[] serviceParams = new String[input.length - 2];
        for(int i = 0; i < serviceParams.length; i++) {
            serviceParams[i] = input[2+i];
        }

        services = new ArrayList<>();
        for(String s: serviceParams) {
            if (s.equals("-b") || s.equals("--button")) { services.add(new NetService(NetService.ServiceType.TOGGLE, "false")); }
            else if (s.equals("-p") || s.equals("--colorpicker")) { services.add(new NetService(NetService.ServiceType.COLORPICKER, "FFFFFF")); }
            else if (s.equals("-t") || s.equals("--textfield")) { services.add(new NetService(NetService.ServiceType.TEXTFIELD, "empty")); }
            else if (s.equals("-c") || s.equals("--checkbox")) { services.add(new NetService(NetService.ServiceType.CHECKBOX, "false")); }
            else { commandPrompt(promptEnum.UNKNOWN_SERVICE, s); }
        }

        initializedParams = true;
        startProviderSocket();
    }

    /**
     * Setup and start {@link ServiceProvider}.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     */
    private static void startProviderSocket() {
        provider = new ServiceProvider(services, path, port);

        provider.start();
    }

    /**
     * Printed information to command prompt and closing application.
     * @param reason        Reason to print the prompt.
     * @param info      Additional information to be printed.
     */
    private static void commandPrompt(promptEnum reason, String info) {
        switch (reason) {
            case HELP:
                System.err.println("" +
                        "USAGE: java Main <file path> <port> [<inputs>]\n\n" +
                        "ARGUMENTS:\n" +
                        "  <file path>\t\t Absolute path to Avahi service file.\n" +
                        "  <port>\t\t Port to use (0 for random port usage).\n" +
                        "  <inputs>\t\t Service elements to make available.\n\n" +
                        "INPUTS (one per):\n" +
                        "  -b, --button\t\t A simple button element.\n" +
                        "  -p, --colorpicker\t A colorpicker element.\n" +
                        "  -t, --textfield\t A textfield element.\n" +
                        "  -c, --checkbox\t A checkbox element.\n\n" +
                        "OPTIONS:\n" +
                        "  --help\t\t Show help information.");
                break;
            case UNKNOWN_SERVICE:
                System.err.println("Unknown input " + info + ". Type --help to show help information.");
                break;
            case NO_PARAMETERS:
                System.err.println("No parameters given. Type --help to show help information.");
                break;
            case NO_FILE:
                System.err.println("Given path is no Avahi service file. Type --help to show help information.");
                break;
            case PORT_UNAVAILABLE:
                System.err.println("Given port is not available. Type --help to show help information.");
                break;
            case PORT_FORMAT:
                System.err.println("Given port is not a number. Type --help to show help information.");
                break;
            case NO_SERVICES:
                System.err.println("Add at least one service. Type --help to show help information.");
                break;
        }
        System.exit(0);
    }

    /**
     * Check if port should be chosen at random or if the availability of pPort needs to be determined.
     * @param pPort         Port to check.
     * @return  Return true if pPort is available. Otherwise return false.
     */
    private static boolean checkPortAvailability(int pPort) {
        if(pPort == 0) {
            port = 0;
            return true;
        } else {
            if(portIsAvailable(pPort)) {
                port = pPort;
            }
        }
        return false;
    }

    /**
     * Apache-SVN, _Contents of /camel/trunk/components/camel-test/src/main/java/org/apache/camel/test/AvailablePortFinder.java_ (davsclaus, 18.01.2012)
     * Retrieved 13.10.2020 from https://svn.apache.org/viewvc/camel/trunk/components/camel-test/src/main/java/org/apache/camel/test/AvailablePortFinder.java?view=markup#l130
     * @param pPort         Port to check availability of.
     * @return  Return true if pPort is available. Otherwise return false.
     */
    private static boolean portIsAvailable(int pPort) {
        ServerSocket ss = null;
        DatagramSocket ds = null;

        try {
            ss = new ServerSocket(pPort);
            ss.setReuseAddress(true);

            ds = new DatagramSocket(pPort);
            ds.setReuseAddress(true);

            return true;
        } catch (IOException e) {
            // Isn't harmful to application
            // Do nothing
        } finally {
            if (ds != null) {
                ds.close();
            }
            if (ss != null) {
                try {
                    ss.close();
                } catch (IOException e) {
                    // Isn't harmful to application
                    // Do nothing
                }
            }

            return false;
        }
    }
}