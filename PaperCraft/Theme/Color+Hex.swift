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
}
