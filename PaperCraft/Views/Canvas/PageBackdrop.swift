//
//  PageBackdrop.swift
//  PaperCraft
//

import SwiftUI

/// Sayfanın arka planı ve kapladığı alan. "Sayfa arka planıyla aynı" seçili kutu bunu çizer.
/// Arka planı çizen görünüm (canvas, önizleme, küçük resim) bunu ortama koyar ve aynı alana
/// `space` adlı koordinat alanını verir; kutu, arka planın kendi yerine düşen parçasını çizer.
/// Böylece gradyanlı arka planda da kutu sayfayla birebir aynı görünür.
struct PageBackdrop {
    static let space = "pageBackdrop"

    let background: ScreenBackground?
    /// Arka planın çizildiği alanın boyutu, `space` koordinatlarında.
    let size: CGSize
}

extension EnvironmentValues {
    @Entry var pageBackdrop: PageBackdrop? = nil
}

extension View {
    /// Bu görünümün alanını sayfa arka planının alanı yapar.
    func pageBackdrop(_ background: ScreenBackground?, size: CGSize) -> some View {
        self
            .coordinateSpace(name: PageBackdrop.space)
            .environment(\.pageBackdrop, PageBackdrop(background: background, size: size))
    }
}
