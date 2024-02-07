import Foundation

/**
    Enum used to determine Application Status.
 */
public enum stateEnum {
    // default
    case NONE
    // no device found
    case NO_DEVICE_FOUND
    // found device but application isn't running
    case MISSING_APPLICATION
    // trying to connect to remote device yields a timeout
    case CONNECTION_TIMEOUT
    // found device and established connection
    case CONNECTION_ACTIVE
    // connection was closed
    case CONNECTION_CLOSED
}

