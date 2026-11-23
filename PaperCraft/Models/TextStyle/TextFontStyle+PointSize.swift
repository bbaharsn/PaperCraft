//
//  TextFontStyle+PointSize.swift
//  PaperCraft
//

import CoreGraphics

extension TextFontStyle {
    /// iOS'un varsayılan boyutları (Dynamic Type "Büyük" ayarında).
    var pointSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .headline: 17
        case .body: 17
        case .caption: 12
        }
    }
}
