//
//  ScreenBackgroundView.swift
//  PaperCraft
//

import SwiftUI

/// Sayfanın arka planını çizer. Canvas, önizleme ve küçük resimler hep bunu kullanır.
struct ScreenBackgroundView: View {
    let background: ScreenBackground?

    /// Okunamayan renkler kağıt rengine düşer.
    private var colors: [Color] {
        (background?.colors ?? []).map { Color(hexString: $0) ?? Theme.paper }
    }

    var body: some View {
        if let background, colors.count > 1 {
            LinearGradient(colors: colors,
                           startPoint: startPoint(of: background.direction),
                           endPoint: endPoint(of: background.direction))
        } else {
            colors.first ?? Theme.paper
        }
    }

    private func startPoint(of direction: GradientDirection) -> UnitPoint {
        switch direction {
        case .vertical: .top
        case .horizontal: .leading
        case .diagonal: .topLeading
        }
    }

    private func endPoint(of direction: GradientDirection) -> UnitPoint {
        switch direction {
        case .vertical: .bottom
        case .horizontal: .trailing
        case .diagonal: .bottomTrailing
        }
    }
}

#Preview {
    ScreenBackgroundView(background: ScreenBackground(kind: .threeColors, color: "#FFD6E0",
                                                      middleColor: "#C7F0D8", endColor: "#BDE0FE",
                                                      direction: .diagonal))
        .frame(width: 150, height: 300)
}
