package dev;

/**
 * Enum to determine reason why application exists whilst trying to resolve parameter-input.
 */
public enum promptEnum {
    NO_FILE,
    NO_PARAMETERS,
    PORT_UNAVAILABLE,
    PORT_FORMAT,
    NO_SERVICES,
    UNKNOWN_SERVICE,
    HELP
}
