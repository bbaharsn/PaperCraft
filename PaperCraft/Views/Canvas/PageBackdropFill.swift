//
//  PageBackdropFill.swift
//  PaperCraft
//

import SwiftUI

/// Sayfa arka planının bu görünümün yerine düşen parçası. Düz renkte sadece o renk;
/// gradyanda bütün arka plan çizilip bu görünümün konumu kadar kaydırılır.
struct PageBackdropFill: View {
    @Environment(\.pageBackdrop) private var backdrop

    var body: some View {
        if let backdrop, (backdrop.background?.colors.count ?? 0) > 1 {
            GeometryReader { geometry in
                let frame = geometry.frame(in: .named(PageBackdrop.space))
                // Görünüm küçültülmüş bir katmandaysa kendi point'lerine çevir
                let scale = frame.width > 0 ? geometry.size.width / frame.width : 1
                ScreenBackgroundView(background: backdrop.background)
                    .frame(width: backdrop.size.width * scale, height: backdrop.size.height * scale)
                    .offset(x: -frame.minX * scale, y: -frame.minY * scale)
            }
        } else {
            ScreenBackgroundView(background: backdrop?.background)
        }
    }
}
