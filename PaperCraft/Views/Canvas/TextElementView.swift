//
//  TextElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki bir metni yazı tipi, stili, kalınlığı, italiği, hizası ve rengiyle çizer.
struct TextElementView: View {
    let properties: ElementProperties

    private var alignment: TextAlign { properties.textAlignment ?? .leading }
    private var style: TextFontStyle { properties.textStyle ?? .body }

    var body: some View {
        Text(properties.text ?? "")
            .font(canvasFont)
            .fontWeight(weight)
            .italic(properties.isItalic ?? false)
            .foregroundStyle(textColor)
            // Birden çok satır olursa satırlar da aynı yöne yaslansın
            .multilineTextAlignment(textAlignment)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
    }

    /// Canvas'taki yazı tipi: sabit boyutlu (cihazın yazı boyutu ayarından bağımsız), çünkü kutu
    /// `TextMeasure` ile yazıya oturtulur; ikisi aynı boyutu kullanmalı.
    private var canvasFont: Font {
        let size = TextMeasure.fontSize(of: properties)
        guard let name = properties.fontName, !name.isEmpty, name != FontFamilies.system else {
            return .system(size: size)
        }
        return .custom(name, fixedSize: size)
    }

    /// Seçilen aileden, stile uygun boyutta bir yazı tipi (cihazın yazı boyutu ayarıyla büyür).
    /// Yazı tipi seçme listesi ve üst bar başlığı bununla çizer.
    static func font(named name: String?, style: TextFontStyle) -> Font {
        let textStyle = fontTextStyle(of: style)
        guard let name, !name.isEmpty, name != FontFamilies.system else {
            return .system(textStyle)
        }
        // relativeTo: kullanıcı cihazda yazı boyutunu büyütürse bu da büyüsün
        return .custom(name, size: style.pointSize, relativeTo: textStyle)
    }

    private static func fontTextStyle(of style: TextFontStyle) -> Font.TextStyle {
        switch style {
        case .largeTitle: .largeTitle
        case .title: .title
        case .headline: .headline
        case .body: .body
        case .caption: .caption
        }
    }

    private var weight: Font.Weight {
        switch properties.fontWeight ?? .regular {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
    }

    private var textColor: Color {
        properties.contentColor.flatMap(Color.init(hexString:)) ?? .primary
    }

    private var textAlignment: TextAlignment {
        switch alignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}

#Preview {
    let samples: [ElementProperties] = [
        ElementProperties(text: "Hoş geldin", textStyle: .largeTitle, fontWeight: .bold),
        ElementProperties(text: "Alt başlık", textStyle: .headline, fontName: "Georgia", isItalic: true,
                          textAlignment: .center),
        ElementProperties(text: "Not", textStyle: .caption, fontName: "Avenir Next", textAlignment: .trailing,
                          contentColor: "#8E8E93"),
    ]
    VStack(spacing: 20) {
        ForEach(samples.indices, id: \.self) { index in
            TextElementView(properties: samples[index])
                .frame(width: 300, height: 44)
        }
    }
    .padding()
    .background(Theme.paper)
}
