import SwiftUI

/**
    SwiftUI View for a simple (toggleable) Button
 */
struct ToggleButtonView: View, ElementComponent {
    private let type = "toggle"
    @State private var isOn: Bool = false;
    @ObservedObject var handler: DeviceHandler
    
    var body: some View {
        Button(action: {
            // if button is tapped, toggle @State isOn and call handler to update
            self.isOn.toggle()
            self.handler.sendUpdate(type: self.type, value: String(self.isOn))
        }) {
            Image(systemName: "power")
                .imageScale(.large)
                .frame(width: 100, height: 100)
                .foregroundColor(self.isOn ? .green : .red)
                .background(Color.white)
                .clipShape(Circle())
                .overlay(RoundedRectangle(cornerRadius: 50)
                            .stroke(Color.gray, lineWidth: 5))
        }
        .buttonStyle(PlainButtonStyle())
        // set @State isOn according to received service value on appearance
        .onAppear() {
            self.isOn = stringToBool(from: self.handler.device!.services[self.type]!)
        }
    }
}

/// Convert service value String to Bool.
///
/// - Parameter from:   String which contains Bool-value.
/// - Returns       Bool-value of input String.
func stringToBool(from: String) -> Bool {
    if(from.lowercased() == "true") { return true }
    else { return false }
}

struct ToggleButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ToggleButtonView(handler: DeviceHandler(tDevice: Device(name: "", ip: "", port: -1, services: ["":""])))
    }
}
