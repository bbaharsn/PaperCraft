//
//  ColorSwatchRow.swift
//  PaperCraft
//

import SwiftUI

/// Yan yana hazır renk daireleri ve en sonda serbest renk seçici.
/// Seçilen renk "#RRGGBB" metni olarak döner.
struct ColorSwatchRow: View {
    @Binding var hex: String
    let presets: [String]

    /// `ColorPicker` `Color` ister; biz modelde hex saklıyoruz, burada çeviriyoruz.
    private var pickerColor: Binding<Color> {
        Binding(
            get: { Color(hexString: hex) ?? .blue },
            set: { hex = $0.hexString }
        )
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        hex = preset
                    } label: {
                        swatch(preset, isSelected: preset.caseInsensitiveCompare(hex) == .orderedSame)
                    }
                    .buttonStyle(.plain)
                }
                ColorPicker("Diğer renk", selection: pickerColor, supportsOpacity: false)
                    .labelsHidden()
            }
            .padding(4)
        }
    }

    private func swatch(_ preset: String, isSelected: Bool) -> some View {
        Circle()
            .fill(Color(hexString: preset) ?? .clear)
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(Theme.ink.opacity(0.3), lineWidth: 1))
            // Seçili rengin etrafında boşluklu bir halka
            .padding(3)
            .overlay(Circle().stroke(isSelected ? Theme.ink : .clear, lineWidth: 2))
    }
}

#Preview {
    @Previewable @State var hex = "#AC5135"
    ColorSwatchRow(hex: $hex, presets: ["#007AFF", "#AC5135", "#111111", "#FFFFFF"])
        .padding()
}
