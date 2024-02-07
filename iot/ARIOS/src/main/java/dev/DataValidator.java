package dev;

import java.util.ArrayList;
import java.util.List;

public class DataValidator {

    /**
     * Validates incoming packet content.
     * @param data      Array containing key, separator, and value.
     * @param provider  {@link ServiceProvider} who called function.
     * @return Return true if data is valid. Otherwise return false.
     */
    public boolean validData(String[] data, ServiceProvider provider) {
        // right format?
        if(data.length != 2) {
            System.err.println("Received packet [" + provider.getSocket().getInetAddress().toString().substring(1) + "]'" + data + "' doesn't conform format!");
            return false;
        }

        // valid key?
        List<String> services = new ArrayList<>();
        for (NetService.ServiceType s: NetService.ServiceType.values()) {
            services.add(s.toString());
        }
        if(!services.contains(data[0])) {
            System.err.println("Couldn't find matching ServiceType [" + provider.getSocket().getInetAddress().toString().substring(1) + "]'" + data + "'!");
            return false;
        }

        // valid value?
        if(checkDataForInjection(data[1])) {
            System.err.println("Received value contains possible injection [" + provider.getSocket().getInetAddress().toString().substring(1) + "]'" + data + "'!");
            return false;
        }

        if(!checkForValueFormat(data[0], data[1])) {
            System.err.println("Received value is in wrong format [" + provider.getSocket().getInetAddress().toString().substring(1) + "]'" + data + "'!");
            return false;
        }

        // everthing is fine
        return true;
    }

    /**
     * Verify that received data-value does not contain possible injection.
     * @param data      {@link String} to check.
     * @return Return true if data contains possible injection. Otherwise return false.
     */
    private boolean checkDataForInjection(String data) {
        if (data.contains("<") && data.contains(">")) {
            return true;
        }

        return false;
    }

    /**
     * Checks value for correctness regarding its corresponding key.
     * @param key       Corresponding key.
     * @param value     Value to check.
     * @return  Return true if value is valid. Otherwise return false.
     */
    private boolean checkForValueFormat(String key, String value) {
        if (key.equals("TOGGLE") || key.equals("CHECKBOX")) {
            if (value.equals("true") || value.equals(("false"))) {
                return true;
            } else {
                return false;
            }
        } else if (key.equals("COLORPICKER")) {
            // not in correct format
            if (value.length() != 6) {
                return false;
            }

            // check if input is in hex-format
            for (int i = 1; i < value.length(); i++) {
                if (Character.digit(value.charAt(i), 16) == -1) {
                    return false;
                }
            }
            return true;
        } else if (key.equals("TEXTFIELD")) {
            // textfield requires no further checks
            return true;
        } else {
            return true;
        }
    }
}
