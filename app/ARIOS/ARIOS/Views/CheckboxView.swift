import SwiftUI

/**
    SwiftUI View for a checkbox.
 */
struct CheckboxView: View, ElementComponent {
    private let type = "checkbox"
    @State private var isChecked: Bool = false;
    @ObservedObject var handler: DeviceHandler
    
    var body: some View {
        VStack {
            Text("Tick me!")
            
            Button(action: {
                // If checkbox is interacted with:
                //  - toggle @State isChecked and
                //  - call handler to update service value.
                self.isChecked.toggle()
                self.handler.sendUpdate(type: self.type, value: String(self.isChecked))
            }) {
                Image(systemName: self.isChecked ? "checkmark.square" : "square")
                    .imageScale(.large)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.black)
            }
            // Set @State isChecked according to received service value.
            .onAppear() {
                self.isChecked = stringToBool(from: self.handler.device!.services[self.type]!)
            }
        }
    }
}

struct CheckboxView_Previews: PreviewProvider {
    static var previews: some View {
        CheckboxView(handler: DeviceHandler(tDevice: Device(name: "", ip: "", port: -1, services: ["":""])))
    }
}
