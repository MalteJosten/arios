import SwiftUI

/**
    SwiftUI View for a textfield.
 */
struct TextfieldView: View, ElementComponent{
    private let type = "textfield"
    @State private var content: String = ""
    @ObservedObject var handler: DeviceHandler
    
    var body: some View {
        TextField("Enter some text", text: $content, onCommit: {
            self.handler.sendUpdate(type: self.type, value: content) // If user commits changes, the handler gets called to update the service value.
        })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .multilineTextAlignment(.leading)
            .frame(width: 250, height: 50)
            // Set its content to received service value.
            .onAppear {
                self.content = self.handler.device!.services[self.type]!
            }
    }
}

struct TextfieldView_Previews: PreviewProvider {
    static var previews: some View {
        TextfieldView(handler: DeviceHandler(tDevice: Device(name: "", ip: "", port: -1, services: ["":""])))
    }
}
