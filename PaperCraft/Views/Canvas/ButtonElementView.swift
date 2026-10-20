//
//  ButtonElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki bir butonu şekli, dolgusu, renkleri ve ikonuyla çizer.
struct ButtonElementView: View {
    let properties: ElementProperties

    private var shape: ButtonShape { properties.shape ?? .rounded }
    private var fill: ButtonFill { properties.fill ?? .filled }
    private var iconPosition: IconPosition { properties.iconPosition ?? .none }

    private var mainColor: Color {
        properties.fillColor.flatMap(Color.init(hexString:)) ?? .blue
    }

    /// Dolu butonda yazı kendi rengini kullanır; diğerlerinde ana renk okunur.
    private var labelColor: Color {
        guard fill == .filled else { return mainColor }
        return properties.contentColor.flatMap(Color.init(hexString:)) ?? .white
    }

    var body: some View {
        // Daire kare alana sığdırılır. Diğer şekillere `aspectRatio` uygulanmaz:
        // `nil` oran bile içeriğin kendi oranına küçültür ve buton çerçeveyi doldurmaz.
        if shape == .circle {
            styledLabel.aspectRatio(1, contentMode: .fit)
        } else {
            styledLabel
        }
    }

    private var styledLabel: some View {
        label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(labelColor)
            .lineLimit(1)
            .padding(.horizontal, shape == .circle ? 0 : 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { background }
    }

    /// Daire butonda yer dar: ikon varsa sadece ikon, yoksa sadece yazı gösterilir.
    @ViewBuilder
    private var label: some View {
        let icon = Image(systemName: properties.symbolName ?? "arrow.right")
        let text = Text(properties.text ?? "")

        if shape == .circle {
            if iconPosition == .none { text } else { icon }
        } else {
            HStack(spacing: 8) {
                if iconPosition == .leading { icon }
                text
                if iconPosition == .trailing { icon }
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        switch fill {
        case .filled: shape.outline.fill(mainColor)
        case .outline: shape.outline.stroke(mainColor, lineWidth: 2)
        case .tinted: shape.outline.fill(mainColor.opacity(0.15))
        case .plain: Color.clear
        }
    }
}

#Preview {
    let samples: [ElementProperties] = [
        ElementProperties(text: "Read More", shape: .rectangle, fill: .filled, fillColor: "#2F5BFF"),
        ElementProperties(text: "Download", symbolName: "icloud.and.arrow.down",
                          shape: .capsule, fill: .tinted, fillColor: "#1E9BFF", iconPosition: .leading),
        ElementProperties(text: "Clear history", symbolName: "xmark",
                          shape: .capsule, fill: .outline, fillColor: "#E53935", iconPosition: .trailing),
        ElementProperties(text: "Explore Now", symbolName: "arrow.right",
                          fill: .plain, fillColor: "#4B2BD6", iconPosition: .trailing),
        ElementProperties(text: "", symbolName: "arrow.right", shape: .circle, fill: .filled,
                          fillColor: "#F5B82E", contentColor: "#111111", iconPosition: .leading),
    ]
    VStack(spacing: 20) {
        ForEach(samples.indices, id: \.self) { index in
            ButtonElementView(properties: samples[index])
                .frame(width: 200, height: 50)
        }
    }
    .padding()
}
