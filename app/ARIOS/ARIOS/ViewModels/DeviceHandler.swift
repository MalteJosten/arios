import Foundation
import Network

/**
    Class which represents ViewModel, hence controlling the Application.
 */
public class DeviceHandler: ObservableObject {
    
    // con_status contains connection status.
    @Published var con_status: stateEnum = stateEnum.NONE
    var deviceFound:            Bool = false
    var activeDevice:           Bool = false
    var activeConnection:       Bool = false
    var connectionWasClosed:    Bool = false
    var timeOut:                Bool = false
    
    // Remote device
    @Published var device: Device?
    
    // TCP-Connection to remote device
    var NWCon: NWConnection?
    
    var arView: ARHandler?
    
    /// Constructor
    ///
    /// - Parameters    tDevice:    Device to set current remote device to.
    init(tDevice: Device) {
        self.device = tDevice
    }
    
    /// Initialize new found device and establish connection.
    ///
    /// - Parameters    foundDevice:    Device which was found in SD process.
    func initDevice(foundDevice: Device) {
        overwriteDevice(found: foundDevice)
        establishConnection()
    }
    
    /// Overwriting current Device
    ///
    /// - Parameters    found: Found Device.
    func overwriteDevice(found: Device) {
        self.activeDevice = true
        updateStatus()
        self.device!.overwrite(d: found)
    }
    
    func setARHandler(handler: ARHandler) {
        self.arView = handler
    }
    
    /// Update connection status after evaluating class variables.
    public func updateStatus() {
        if (!self.device!.running && self.activeDevice) {
            DispatchQueue.main.async { self.con_status = stateEnum.MISSING_APPLICATION }
        } else if (!self.deviceFound) {
            DispatchQueue.main.async { self.con_status = stateEnum.NO_DEVICE_FOUND }
        } else if (self.timeOut) {
            DispatchQueue.main.async { self.con_status = stateEnum.CONNECTION_TIMEOUT }
        } else if (self.connectionWasClosed) {
            DispatchQueue.main.async { self.con_status = stateEnum.CONNECTION_CLOSED }
        } else if (self.activeDevice && self.activeConnection) {
            DispatchQueue.main.async { self.con_status = stateEnum.CONNECTION_ACTIVE }
        } else {
            DispatchQueue.main.async { self.con_status = stateEnum.NONE }
        }
        
        DispatchQueue.main.async {
            print(self.con_status)
        }
    }
    
    /// Retrieve connection status.
    ///
    /// - Returns       con_status as String.
    public func getConStatusText() -> String {
        switch con_status {
        case stateEnum.NONE:
            return ""
        case stateEnum.NO_DEVICE_FOUND:
            return "No matching device found!"
        case stateEnum.MISSING_APPLICATION:
            return "Found device but it's not running the desired application!"
        case stateEnum.CONNECTION_TIMEOUT:
            return "Connection timeout!"
        case stateEnum.CONNECTION_ACTIVE:
            return "Name: \(self.device?.name ?? "none") | IP: \(self.device?.ipString ?? "") | Port: \(self.device?.port ?? -1) | Service-Count: \(self.device?.getServiceArray().count ?? 0)"
        case stateEnum.CONNECTION_CLOSED:
            return "Connection was closed!"
        }
    }
    
    // MARK: - Bonjour
    
    /// Start Service Discovery.
    ///
    /// - Parameters    imageName:  Name of tracked image. Used to find remote device.
    func startBonjour(imageName: String) {
        DispatchQueue.global(qos: .background).async {
            // Searching for corresponding device in network
            let b = Bonjour()
            b.startSearch(searchFor: imageName);
            
            var timeOut = 0
        
            // Waiting for device to be found
            while(true) {
                // Timeout after 1 second
                if(timeOut >= 10) {
                    self.activeDevice = false
                    self.deviceFound = false
                    self.updateStatus()
                    
                    self.arView!.resetUUID()
                    
                    break
                }
                
                // Device was found
                if(b.device.name == imageName) {
                    self.deviceFound = true
                    self.initDevice(foundDevice: b.device)
                    break
                }
                
                timeOut += 1
                
                // Sleep for 0.1 seconds
                usleep(100000)
            }
        }
    }
    
    // MARK: - Connection
    
    /// Setup NWCon and establish TCP-Connection to remote device.
    func establishConnection() {
        DispatchQueue.global(qos: .background).async {
            
            // Waiting for device to be setup up, i.e. be ready
            while (self.device!.ready == false) { }
            
            // If the device isn't running desired application reset Image Tracking and don't establish connection.
            if (!self.device!.running) {
                self.arView?.resetUUID()
                return
            }
            
            // Setup and start NWConnection.
            DispatchQueue.main.async {
                self.NWCon = NWConnection(host: NWEndpoint.Host(self.device!.ipString), port: NWEndpoint.Port("\(self.device!.port)")!, using: .tcp)
                self.NWCon?.start(queue: .main)
            }
            
            
            // Waiting for connection establishement.
            var timeOut = 0
            while (self.NWCon?.state != NWConnection.State.ready) {
                // timeOut of 1 second
                if(timeOut < 10) {
                    timeOut += 1
                    
                    // sleep for 0.1 seconds
                    usleep(100000)
                }
                // Connection couldn't be established in 1 second -> timeout
                else {
                    self.timeOut = true
                    self.updateStatus()
                    self.disconnect()
                    return
                }
            }
            
            // Connection established
            DispatchQueue.main.async {
                self.activeConnection = true
                self.timeOut = false
                self.updateStatus()
            }
            
            // Prepare to receive TCP-package.
            self.setupReceive()
        }
    }
    
    /// Send Service-Element-Type with updated value to remote device.
    ///
    /// - Parameters    type:   Service-Element-Type.
    ///               value: Updated value to transmit.
    func sendUpdate(type: String, value: String) {
        let text = type.uppercased() + "=" + value
        let data = (text + "\n").data(using: .utf8)
        
        self.NWCon?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed({ p in }))
    }
    
    /// Prepare to receive TCP-package.
    private func setupReceive() {
        NWCon!.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                // Receiving a package from remote device signals disconnection
                DispatchQueue.global().async {
                    self.connectionWasClosed = true
                    self.updateStatus()
                    sleep(2)
                    self.connectionWasClosed = false
                    self.updateStatus()
                }
                self.disconnect()
            }
            if error != nil {
                self.disconnect()
            }
        }
    }
    
    /// Disconnect from current device and connection.
    func disconnect() {
        // Reset image tracking.
        self.arView?.resetUUID()
        
        // Reset Device.
        self.device!.reset()
        
        // Cancel TCP-connection.
        self.NWCon?.cancel();
        
        // Update con_status
        self.activeConnection = false
        self.activeDevice = false
        updateStatus()
    }
}
