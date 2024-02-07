import SwiftUI

/**
    SwiftUI View which appears after successfully connecting to remote device.
 */
struct DeviceView: View {
    @ObservedObject var handler: DeviceHandler
    
    var body: some View {
        VStack {
            Spacer()
            Spacer()
            HStack {
                Spacer()
                // Generating service-element views according to available services.
                ForEach(Array(zip(self.handler.device!.getServiceArray().indices, self.handler.device!.getServiceArray().sorted())), id:\.0) { index, item in
                    switch item {
                    case "toggle":
                        ToggleButtonView(handler: self.handler)
                    case "colorpicker":
                        ColorPickerView(handler: self.handler)
                    case "textfield":
                        TextfieldView(handler: self.handler)
                    case "checkbox":
                        CheckboxView(handler: self.handler)
                    // if no services are available
                    default:
                        Text("no elements avialable")
                            .scaleEffect(2)
                            .foregroundColor(.red)
                            .font(.title)
                    }
                    Spacer()
                }
            }
            Spacer()
            // Add button to cancel connection to remote device.
            Button("Disconnect") {
                self.handler.disconnect();
            }
            .padding()
            .foregroundColor(.black)
            .background(Color.white)
            .border(Color.black, width: 2)
            Spacer()
        }
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceView(handler: DeviceHandler(tDevice: Device(name: "", ip: "", port: -1, services: ["":""])))
    }
}
