import SwiftUI

/**
    SwiftUI View for a colorpicker.
 */
struct ColorPickerView: View, ElementComponent {
    private let type = "colorpicker"
    @State private var color = Color.white
    @ObservedObject var handler: DeviceHandler
    
    var body: some View {
        ColorPicker("", selection: $color, supportsOpacity: false)
            .background(Color.white.opacity(0))
            .frame(width: 100, height: 100)
            .scaleEffect(2)
            // Set selected color (@State color) to received service value on appearance.
            .onAppear {
                self.color = stringToColor(from: self.handler.device!.services[self.type]!)
            }
            // Call handler to update its service value (color) after changed by user.
            .onChange(of: color, perform: { _ in
                self.handler.sendUpdate(type: self.type, value: colorToString(from: self.color))
            })
    }
    
    /// Convert String to Color.
    ///
    /// - Parameters    from:   String which contains color-values in HEX format.
    /// - Returns           The converted Color if the conversion was successful. Otherwise Color.black.
    func stringToColor(from hexString: String) -> Color {
        if let rgbValue = UInt(hexString, radix: 16) {
            let red   =  CGFloat((rgbValue >> 16) & 0xff) / 255
            let green =  CGFloat((rgbValue >>  8) & 0xff) / 255
            let blue  =  CGFloat((rgbValue      ) & 0xff) / 255
            
            return Color(UIColor(red: red, green: green, blue: blue, alpha: 1.0).cgColor)
        }
        else {
            return Color(UIColor.black.cgColor)
        }
    }
    
    /// Convert Color to String.
    ///
    /// - Parameters    from:   Color which should be converted.
    /// - Returns           The String containing color-values in HEX format.
    func colorToString(from color: Color) -> String {
        let colorIntensities = color.cgColor?.components
        var colorHex: [String] = ["", "", ""]
        for i in 0...2 {
            colorHex[i] = String(format: "%02X", Int(colorIntensities![i] * 255));
        }
        
        return colorHex.joined()
    }
}

struct ColorPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerView(handler: DeviceHandler(tDevice: Device(name: "", ip: "", port: -1, services: ["":""])))
    }
}
