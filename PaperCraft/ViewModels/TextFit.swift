//
//  TextFit.swift
//  PaperCraft
//

import CoreGraphics

/// Metin kutusunu yazıya oturtma kuralları.
nonisolated enum TextFit {
    /// Yazının boyutunu değiştiren özelliklerden biri değişti mi? (Renk ya da bağlantı değişince kutu yerinde kalır.)
    static func changesSize(from old: ElementProperties, to new: ElementProperties) -> Bool {
        old.text != new.text || old.textStyle != new.textStyle || old.fontName != new.fontName
            || old.fontWeight != new.fontWeight || old.isItalic != new.isItalic || old.contentScale != new.contentScale
    }

    /// Yazının kutu içinde çizildiği yere oturan kutu: yatayda hizaya göre (sola, ortaya, sağa),
    /// dikeyde ortada. Böylece kutu küçülürken yazı yerinden oynamaz. Sayfanın yanlarından taşmaz.
    static func rect(for size: CGSize, in box: CGRect, alignment: TextAlign, canvasWidth: CGFloat) -> CGRect {
        let x: CGFloat
        switch alignment {
        case .leading: x = box.minX
        case .center: x = box.midX - size.width / 2
        case .trailing: x = box.maxX - size.width
        }
        let clampedX = min(max(x, 0), max(canvasWidth - size.width, 0))
        return CGRect(x: clampedX, y: max(box.midY - size.height / 2, 0), width: size.width, height: size.height)
    }
}
