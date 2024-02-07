package dev;

public class NetService {
    /**
     * Enum to determine service types.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     */
    public enum ServiceType {
        TOGGLE,
        COLORPICKER,
        TEXTFIELD,
        CHECKBOX
    }

    private ServiceType type;
    private String value;

    /**
     * Class constructor.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     *
     * @param pType     {@link ServiceType} to use for {@link NetService}.
     * @param pValue    The value which the type holds.
     */
    public NetService(ServiceType pType, String pValue) {
        this.type = pType;
        this.value = pValue;
    }

    /**
     * Sets the class variable value to given value (pValue).
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     *
     * @param pValue    The value to overwrite class variable value with.
     */
    public void setValue(String pValue) { this.value = pValue; }

    /**
     * Returns class variable value.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     *
     * @return  A {@link String} value.
     */
    public String getValue() { return this.value; }

    /**
     * Returns {@link ServiceType} of class.
     *
     * @author Malte Josten, Universität Duisburg-Essen
     * @author malte.josten@stud.uni-due.de
     *
     * @return  A {@link ServiceType} type.
     */
    public ServiceType getType() { return this.type; }

}
