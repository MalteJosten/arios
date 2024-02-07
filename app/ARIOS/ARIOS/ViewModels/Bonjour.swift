import Foundation
import Network

/**
    Class to handle Bonjour (Service Discovery) operations.
 */
class Bonjour: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    var nsb : NetServiceBrowser!
    
    // NetService used to resolve discovered device.
    var discoveredService = NetService()
    // Discovered remote device.
    var device = Device(name: "", ip: "", port: -1, services: [String: String]())
    
    // zeroconf service type to search for.
    let serviceType = "_http._tcp."
    
    // Indicates the name of the remote device which is searched for.
    var searchFor: String = ""
    
    /// Starting Service Discovery search on local network.
    ///
    /// - Parameters    searchFor:  String which contains the device-name to search for.
    func startSearch (searchFor: String) {
        self.searchFor = searchFor
        
        self.discoveredService = NetService()
        self.nsb = NetServiceBrowser()
        self.nsb.delegate = self
        
        DispatchQueue.main.async {
            self.nsb.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
            self.nsb.searchForServices(ofType: self.serviceType, inDomain: "")
            //RunLoop.current.run()
        }
    }

    // MARK: - NetServerBrowserDelegate
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        tryToResolve()
    }
    
    /// Found NetService (remote device).
    ///
    /// - Parameters    aNetService:    Found NetService.
    ///               moreComing:   Are more NetServices being found?
    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didFind aNetService: NetService, moreComing: Bool) {
        // If the found device is the one we're looking for, try to resolve it.
        if(aNetService.name == self.searchFor) {
            aNetService.delegate = self
            aNetService.resolve(withTimeout: 3)
            
            self.discoveredService = aNetService
        }
        
        // If no more devices being found, stop the search.
        if !moreComing {
            self.nsb.stop()
        }
    }
    
    func netServiceBrowser(_ aNetServiceBrowser: NetServiceBrowser, didRemove aNetService: NetService, moreComing: Bool) {
        self.discoveredService = NetService()
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("Resolve error:", sender, errorDict)
    }
    
    // MARK: - Helper functions
    
    /// Trying to resolve most recent discovered NetService
    func tryToResolve () {
        // If its port is -1 it isn't resolve yet. Try it one more time.
        if self.discoveredService.port == -1 {
            self.discoveredService.delegate = self
            self.discoveredService.resolve(withTimeout:10)
        }
        // It got resolved. Create a Device with its properties, extract available service elements and stop the search.
        else {
            let d = Device(name: self.discoveredService.name,
                           ip: getIPv4String(service: self.discoveredService),
                           port: self.discoveredService.port,
                           services: [String: String]())
            d.extractElements(dict: txtRecordDataToStringDictionary(service: self.discoveredService))
            self.device = d
            
            self.nsb.stop()
        }
    }
    
    /// Retrieve the IPv4-Address of a NetService.
    ///
    /// - Parameters    service:    NetService to retrieve the IPv4-Address from.
    /// - Returns           IPv4-Address as String.
    func getIPv4String(service: NetService) -> String{
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        
        guard let data = service.addresses?.first else { return "" }
        data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Void in
                let sockaddrPtr = pointer.bindMemory(to: sockaddr.self)
                guard let unsafePtr = sockaddrPtr.baseAddress else { return }
                guard getnameinfo(unsafePtr, socklen_t(data.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
                    return
                }
            }
        return String(cString:hostname)
    }
    
    /// Retrieve <txt-record>s and convert it to a Dictionary.
    ///
    /// - Parameters    service:    NetService to retrieve the <txt-record>s from
    /// - Returns           Dictionary containing <txt-record>s in format <Key>: <Value>.s
    func txtRecordDataToStringDictionary(service: NetService) -> [String: String] {
        var stringDict = [String: String]()
        
        if let data = service.txtRecordData() {
            let dict = NetService.dictionary(fromTXTRecord: data)
            
            dict.forEach { (key: String, value: Data) in
                stringDict[key] = String(data: value, encoding: String.Encoding.utf8)
            }
        }
        
        return stringDict
    }

}
