//
//  DashedOutline.swift
//  PaperCraft
//

import SwiftUI

/// Birlikte taşınan ya da toplu seçilen elemanın etrafındaki kesikli çizgi (Figma'daki gibi).
/// Kalınlık ve desen ekranda sabit kalsın diye tuvalin ölçeğine bölünür.
struct DashedOutline: View {
    let scale: CGFloat

    var body: some View {
        Rectangle()
            .stroke(.blue, style: StrokeStyle(lineWidth: 1.5 / scale, dash: [4 / scale, 3 / scale]))
            .allowsHitTesting(false)
    }
}

#Preview {
    RoundedRectangle(cornerRadius: 8)
        .fill(Theme.accent)
        .frame(width: 160, height: 60)
        .overlay { DashedOutline(scale: 1) }
        .padding()
}
