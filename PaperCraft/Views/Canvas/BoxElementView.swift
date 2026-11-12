//
//  BoxElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki düz kutu: kart zemini, etiket ya da daire olarak kullanılır.
struct BoxElementView: View {
    let properties: ElementProperties

    private var fill: Color {
        properties.fillColor.flatMap(Color.init(hexString:)) ?? .white
    }

    private var borderColor: Color {
        properties.borderColor.flatMap(Color.init(hexString:)) ?? .gray
    }

    /// Dolgu: seçilen renk ya da "Sayfa arka planıyla aynı" ise sayfanın arka planı.
    @ViewBuilder
    private var fillView: some View {
        if properties.matchesPageBackground ?? false {
            PageBackdropFill()
        } else {
            fill
        }
    }

    var body: some View {
        let shape = FrameOutline(shape: properties.frameShape ?? .rounded,
                                 cornerRadius: properties.cornerRadius ?? 12)
        let borderWidth = max(properties.borderWidth ?? 1, 0)

        fillView
            .clipShape(shape)
            .overlay {
                if borderWidth > 0 {
                    shape.strokeBorder(borderColor, lineWidth: borderWidth)
                }
            }
            .shadow(color: .black.opacity(properties.hasShadow ?? false ? 0.15 : 0), radius: 6, y: 3)
    }

    /// Köşe yuvarlaklığı kısa kenarın yarısını geçemez; geçerse kutu hap ya da daire olur.
    static func clampedRadius(_ radius: Double, in size: CGSize) -> Double {
        min(max(radius, 0), min(size.width, size.height) / 2)
    }
}

#Preview {
    HStack(spacing: 20) {
        BoxElementView(properties: ElementProperties(fillColor: "#FFFFFF", cornerRadius: 12,
                                                     borderWidth: 1, borderColor: "#E5E5EA", hasShadow: true))
            .frame(width: 140, height: 180)
        BoxElementView(properties: ElementProperties(fillColor: "#25D366", frameShape: .circle, borderWidth: 0))
            .frame(width: 80, height: 60)
    }
    .padding()
    .background(Theme.paper)
}
