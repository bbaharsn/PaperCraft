//
//  ButtonShape+Outline.swift
//  PaperCraft
//

import SwiftUI

/// Butonun çizimi ve seçim çizgisi aynı şekli kullansın diye tek yerde tanımlı.
extension ButtonShape {
    /// "Yuvarlak" butonun köşe yarıçapı (point).
    static let roundedCornerRadius: CGFloat = 12

    /// Şeklin SwiftUI karşılığı.
    var outline: AnyShape {
        switch self {
        case .rectangle: AnyShape(Rectangle())
        case .rounded: AnyShape(RoundedRectangle(cornerRadius: Self.roundedCornerRadius))
        case .capsule: AnyShape(Capsule())
        case .circle: AnyShape(Circle())
        }
    }

    /// Verilen boyuttaki şeklin köşe kıvrımı (point). Tutamaçları kıvrımın üstüne oturtmak için.
    func cornerRadius(in size: CGSize) -> CGFloat {
        let shortSide = min(size.width, size.height)
        switch self {
        case .rectangle: return 0
        case .rounded: return min(Self.roundedCornerRadius, shortSide / 2)
        case .capsule, .circle: return shortSide / 2
        }
    }
}
