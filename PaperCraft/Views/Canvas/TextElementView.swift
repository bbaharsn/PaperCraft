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
            .font(Self.font(named: properties.fontName, style: style))
            .fontWeight(weight)
            .italic(properties.isItalic ?? false)
            .foregroundStyle(textColor)
            // Birden çok satır olursa satırlar da aynı yöne yaslansın
            .multilineTextAlignment(textAlignment)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
    }

    /// Seçilen aileden, stile uygun boyutta bir yazı tipi.
    /// Yazı tipi seçme listesi de satırları bununla çizer.
    static func font(named name: String?, style: TextFontStyle) -> Font {
        let textStyle = fontTextStyle(of: style)
        guard let name, !name.isEmpty, name != FontFamilies.system else {
            return .system(textStyle)
        }
        // relativeTo: kullanıcı cihazda yazı boyutunu büyütürse bu da büyüsün
        return .custom(name, size: pointSize(of: style), relativeTo: textStyle)
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

    /// iOS'un varsayılan boyutları; özel yazı tiplerinde aynı büyüklüğü vermek için.
    private static func pointSize(of style: TextFontStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .headline: 17
        case .body: 17
        case .caption: 12
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
