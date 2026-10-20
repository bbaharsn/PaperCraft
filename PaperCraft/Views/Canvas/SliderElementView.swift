//
//  SliderElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki bir kaydırıcıyı değeri, rengi, yan ikonları ve değer yazısıyla çizer.
/// Parçaların genişlikleri `SliderLayout`'tan gelir; çubuk kalan yeri doldurur.
struct SliderElementView: View {
    let properties: ElementProperties

    private var showsSideIcons: Bool { properties.showsSideIcons ?? false }
    private var showsValue: Bool { properties.showsValue ?? false }

    /// Çubuğun dolu kısmının rengi
    private var tintColor: Color {
        properties.fillColor.flatMap(Color.init(hexString:)) ?? .blue
    }

    var body: some View {
        HStack(spacing: SliderLayout.spacing) {
            if showsSideIcons { icon(properties.minSymbolName ?? "minus") }
            Slider(value: .constant(properties.sliderValue), in: properties.sliderRange)
                .tint(tintColor)
            if showsSideIcons { icon(properties.maxSymbolName ?? "plus") }
            if showsValue {
                Text(properties.sliderValue, format: .number.precision(.fractionLength(0...1)))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: SliderLayout.valueWidth, alignment: .trailing)
            }
        }
        .font(.system(size: 17))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .foregroundStyle(.secondary)
            .frame(width: SliderLayout.iconWidth)
    }
}

#Preview {
    let samples: [ElementProperties] = [
        ElementProperties(value: 0.5, minValue: 0, maxValue: 1, fillColor: "#007AFF"),
        ElementProperties(value: 0.3, minValue: 0, maxValue: 1, fillColor: "#AC5135",
                          showsSideIcons: true, minSymbolName: "moon", maxSymbolName: "sun.max"),
        ElementProperties(value: 70, minValue: 0, maxValue: 100, fillColor: "#34C759",
                          showsSideIcons: true, minSymbolName: "minus", maxSymbolName: "plus", showsValue: true),
    ]
    VStack(spacing: 20) {
        ForEach(samples.indices, id: \.self) { index in
            SliderElementView(properties: samples[index])
                .frame(width: 300 + SliderLayout.extraWidth(for: samples[index]), height: 44)
        }
    }
    .padding()
    .background(Theme.paper)
}
