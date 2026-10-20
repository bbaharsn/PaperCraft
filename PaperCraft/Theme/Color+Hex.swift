//
//  Color+Hex.swift
//  PaperCraft
//

import SwiftUI

extension Color {
    /// Figma'daki gibi hex kodla renk oluşturur: `Color(hex: 0xFBF7EE)`
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    /// JSON'da saklanan metinden renk oluşturur: `Color(hexString: "#AC5135")`
    /// Metin geçerli bir 6 haneli hex değilse `nil` döner.
    init?(hexString: String) {
        let digits = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        self.init(hex: value)
    }

    /// Rengi JSON'a yazılabilecek "#RRGGBB" metnine çevirir (ör. `ColorPicker`'dan gelen renk).
    var hexString: String {
        let resolved = resolve(in: EnvironmentValues())
        let red = Int((resolved.red * 255).rounded())
        let green = Int((resolved.green * 255).rounded())
        let blue = Int((resolved.blue * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
