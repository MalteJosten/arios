import Foundation
import Network
import Combine

/**
    Class which represents a remote device.
 */

public class Device: Equatable, ObservableObject {
    // Device's network and application properties
    @Published var name: String
    @Published var ipv4: IPv4Address
    @Published var ipString: String
    @Published var port: Int
    @Published var services: [String: String]   // Services are stored <ServiceType>: <Value>
    @Published var availableServices = ["colorpicker", "toggle", "textfield", "checkbox"]   // Services which the App is capable to display.
    @Published var running: Bool = false    // Is the desired applicaton running on the remote device?
    
    // Used to determine if Device is ready be used.
    var ready: Bool = false
    
    init(name: String, ip: String, port: Int, services: [String: String]) {
        self.name = name
        self.ipString = ip
        self.ipv4 = ip != "" ? IPv4Address.init(ip)! : IPv4Address.init("127.0.0.1")!
        self.port = port
        self.services = services
    }
    
    /// Extract service elements from all <txt-records> of discovered remote device.
    ///
    /// - Parameters   dict:    Dictionary containg <txt-records> of  device.
    func extractElements(dict: [String: String]){
        dict.forEach { (key: String, value: String) in
            if (key == "running") {
                running = value.lowercased() == "true" ? true : false
            }
            
            if (self.availableServices.contains(key)) {
                services[key] = value
            }
        }
    }
    
    /// Overwrite network and remote application properties.
    ///
    /// - Parameters d:     Device used to override properties with.
    func overwrite(d: Device) {
        DispatchQueue.main.async {
            self.name = d.name
            self.ipString = d.ipString
            self.ipv4 = d.ipv4
            self.port = d.port
            self.services = d.services
            self.running = d.running
            self.ready = true
        }
    }
    
    /// Reset current Device.
    func reset() {
        overwrite(d: Device(name: "", ip: "", port: -1, services: ["":""]))
    }
    
    /// Getting the device's services as String Array
    ///
    /// - Returns   Service Types as String Array.
    func getServiceArray() -> [String] {
        return Array(self.services.keys)
    }
    
    /// Printing device info.
    func printInfo() {
        print("name: \(self.name), ip: \(self.ipString), port: \(self.port), service-count: \(self.services.count), running: \(self.running)")
    }
    
    // Function to compare to Device objects. Needed to implement Equatable.
    public static func == (lhs: Device, rhs: Device) -> Bool {
        return (lhs.name == rhs.name) && (lhs.ipv4 == rhs.ipv4) && (lhs.availableServices == rhs.availableServices)
    }
}
