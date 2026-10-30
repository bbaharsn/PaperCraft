//
//  PreviewLayout.swift
//  PaperCraft
//

import CoreGraphics

/// Referans tuvali (393×852) o anki telefona yerleştirir.
/// Eleman boyutları genişliğe göre ölçeklenir; dikey konumlar durum çubuğunun altındaki
/// alana yayılır. Böylece üst bar güvenli alanın hemen altına, alt menü en alta oturur.
nonisolated struct PreviewLayout {
    /// Tasarımın çizildiği alan (ekran point'i).
    let stageSize: CGSize
    /// Durum çubuğu / çentik yüksekliği (ekran point'i).
    let topInset: CGFloat

    private var reference: CGSize { CanvasView.referenceSize }

    /// Gerçek boyutta çizilen tasarımın ekrana büyütülme oranı.
    var scale: CGFloat { stageSize.width / reference.width }

    /// Durum çubuğunun altında kalan alanın yüksekliği (tuval point'i).
    var designHeight: CGFloat { (stageSize.height - topInset) / scale }

    /// Elemanın, durum çubuğunun altındaki alanda merkezi (tuval point'i).
    func center(of frame: NormalizedFrame) -> CGPoint {
        let height = frame.height * reference.height
        let travel = reference.height - height
        // Elemanın üstünde kalan boşluğun oranı: 0 en üstte, 1 en altta
        let progress = travel > 0 ? frame.y * reference.height / travel : 0
        return CGPoint(x: (frame.x + frame.width / 2) * reference.width,
                       y: progress * (designHeight - height) + height / 2)
    }

    /// Klavye açıkken elemanın görünmesi için tasarımın ne kadar yukarı kayması gerektiği
    /// (ekran point'i). Eleman zaten görünüyorsa ya da klavye kapalıysa 0.
    func keyboardLift(for frame: NormalizedFrame, keyboardHeight: CGFloat) -> CGFloat {
        guard keyboardHeight > 0 else { return 0 }
        let margin: CGFloat = 16
        let height = frame.height * reference.height * scale
        let elementTop = topInset + center(of: frame).y * scale - height / 2
        let needed = elementTop + height - (stageSize.height - keyboardHeight - margin)
        // Eleman çok uzunsa üst kenarı durum çubuğunun altına geçecek kadar kaydırma
        return max(0, min(needed, elementTop - topInset - margin))
    }

    /// Telefonlardan geniş ekranlarda (iPad, Mac) tasarım telefon oranında kalır.
    static func stageWidth(for screen: CGSize) -> CGFloat {
        min(screen.width, screen.height * 0.6)
    }
}
