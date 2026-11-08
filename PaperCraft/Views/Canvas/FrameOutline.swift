//
//  FrameOutline.swift
//  PaperCraft
//

import SwiftUI

/// `FrameShape`'in çizilen hali. Kutu bununla boyanır, fotoğraf bununla kırpılır.
/// Kenarlık için `strokeBorder` kullanılabilsin diye `InsettableShape`.
struct FrameOutline: InsettableShape {
    var shape: FrameShape
    /// Sadece `.rounded`'da kullanılır; kısa kenarın yarısını geçemez.
    var cornerRadius: Double = 0
    private var insetAmount: CGFloat = 0

    init(shape: FrameShape, cornerRadius: Double = 0) {
        self.shape = shape
        self.cornerRadius = cornerRadius
    }

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .rectangle:
            return Path(rect.insetBy(dx: insetAmount, dy: insetAmount))
        case .rounded:
            let radius = BoxElementView.clampedRadius(cornerRadius, in: rect.size) - insetAmount
            return Path(roundedRect: rect.insetBy(dx: insetAmount, dy: insetAmount),
                        cornerRadius: max(radius, 0), style: .continuous)
        case .capsule:
            let inner = rect.insetBy(dx: insetAmount, dy: insetAmount)
            return Path(roundedRect: inner, cornerRadius: min(inner.width, inner.height) / 2)
        case .circle:
            return Path(ellipseIn: Self.centeredSquare(in: rect).insetBy(dx: insetAmount, dy: insetAmount))
        }
    }

    func inset(by amount: CGFloat) -> FrameOutline {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    /// Çerçevenin ortasındaki en büyük kare; daire bunun içine çizilir.
    static func centeredSquare(in rect: CGRect) -> CGRect {
        let side = min(rect.width, rect.height)
        return CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side)
    }
}
