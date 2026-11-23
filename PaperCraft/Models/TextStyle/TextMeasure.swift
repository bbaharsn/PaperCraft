//
//  TextMeasure.swift
//  PaperCraft
//

import CoreGraphics
import Foundation
#if canImport(UIKit)
import UIKit
private typealias PlatformFont = UIFont
private typealias PlatformFontDescriptor = UIFontDescriptor
#else
import AppKit
private typealias PlatformFont = NSFont
private typealias PlatformFontDescriptor = NSFontDescriptor
#endif

/// Bir metin elemanının yazısının kapladığı alan; kutu yazıya oturtulurken kullanılır.
/// Canvas'taki çizimle (`TextElementView`) aynı yazı tipi, boyut, kalınlık ve italikle ölçer.
nonisolated enum TextMeasure {
    /// Yazının çevresinde bırakılan pay (point); ölçüm ile çizim arasındaki küçük farklar yazıyı kesmesin.
    static let padding = CGSize(width: 4, height: 2)

    /// Yazının boyutu, payla birlikte. `maxWidth`'ten uzun satırlar alt satıra geçer.
    static func size(of properties: ElementProperties, maxWidth: CGFloat) -> CGSize {
        let text = properties.text ?? ""
        let font = font(for: properties)
        let attributed = NSAttributedString(string: text.isEmpty ? " " : text, attributes: [.font: font])
        let bounds = attributed.boundingRect(with: CGSize(width: max(maxWidth - padding.width, 1),
                                                          height: .greatestFiniteMagnitude),
                                             options: [.usesLineFragmentOrigin, .usesFontLeading],
                                             context: nil)
        return CGSize(width: min(ceil(bounds.width) + padding.width, maxWidth),
                      height: ceil(bounds.height) + padding.height)
    }

    /// Canvas'taki yazının boyutu (point): stilin boyutu × içerik ölçeği.
    static func fontSize(of properties: ElementProperties) -> CGFloat {
        (properties.textStyle ?? .body).pointSize * properties.scale
    }

    private static func font(for properties: ElementProperties) -> PlatformFont {
        let size = fontSize(of: properties)
        let weight = fontWeight(properties.fontWeight ?? .regular)
        var font: PlatformFont
        if let name = properties.fontName, !name.isEmpty, name != FontFamilies.system {
            let descriptor = PlatformFontDescriptor(fontAttributes: [
                .family: name,
                .traits: [PlatformFontDescriptor.TraitKey.weight: weight],
            ])
            font = PlatformFont(descriptor: descriptor, size: size) ?? .systemFont(ofSize: size, weight: weight)
        } else {
            font = .systemFont(ofSize: size, weight: weight)
        }
        if properties.isItalic ?? false {
            #if canImport(UIKit)
            if let italic = font.fontDescriptor.withSymbolicTraits(.traitItalic) {
                font = PlatformFont(descriptor: italic, size: size)
            }
            #else
            let italic = font.fontDescriptor.withSymbolicTraits(.italic)
            font = PlatformFont(descriptor: italic, size: size) ?? font
            #endif
        }
        return font
    }

    private static func fontWeight(_ weight: TextWeight) -> PlatformFont.Weight {
        switch weight {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
    }
}
