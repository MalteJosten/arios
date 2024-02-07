import SwiftUI

/**
    Main SwiftUI View which contains the Debug-Panel at the top of the screen, the AR-View and if the App connects to a remote device its corresponding View.
 */

// MARK: - ARIndicator

/// Setup a wrapper for the ARView to use it as a SwiftUI View.
struct ARView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ARHandler
    
    var handler: DeviceHandler
    
    func makeUIViewController(context: Context) -> ARHandler {
        return ARHandler(tHandler: handler)
    }
    
    func updateUIViewController(_ uiViewController: ARView.UIViewControllerType, context: UIViewControllerRepresentableContext<ARView>) { }
}

// MARK: - ContentView

struct ContentView: View {
    @ObservedObject var handler = DeviceHandler(tDevice: Device(name: "", ip: "", port: -1, services: [String:String]()))
    
    var body: some View {
        VStack {
            // Debug-/Information-Panel
            Text(self.handler.getConStatusText())
            
            // Content
            ZStack {
                // AR View
                ARView(handler: self.handler)
                
                // If avialable: DeviceView
                if(self.handler.con_status == stateEnum.CONNECTION_ACTIVE) {
                    DeviceView(handler: self.handler)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
