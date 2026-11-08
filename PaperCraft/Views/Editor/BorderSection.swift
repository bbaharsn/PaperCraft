//
//  BorderSection.swift
//  PaperCraft
//

import SwiftUI

/// Seçili elemanın kenarlığı (`borderWidth`, `borderColor`): kalınlık ve renk. Kutu ve fotoğraf kullanır.
struct BorderSection: View {
    let viewModel: EditorViewModel
    /// Alan boşken kullanılan kalınlık (kutuda 1, fotoğrafta 0).
    let defaultWidth: Double
    let defaultColor: String
    let presets: [String]

    private var width: Double {
        viewModel.selectedElement?.properties.borderWidth ?? defaultWidth
    }

    var body: some View {
        Section("Kenarlık") {
            Stepper(value: viewModel.binding(\.borderWidth, default: defaultWidth), in: 0...8) {
                Text(width == 0 ? "Kenarlık yok" : "\(Int(width)) pt")
            }
            if width > 0 {
                ColorSwatchRow(hex: viewModel.binding(\.borderColor, default: defaultColor), presets: presets)
            }
        }
    }
}
