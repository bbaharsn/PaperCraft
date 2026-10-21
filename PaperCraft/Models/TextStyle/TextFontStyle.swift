//
//  TextFontStyle.swift
//  PaperCraft
//

import Foundation

/// Metnin yazı stili (boyutu); kalınlık ayrıca `fontWeight`'te durur.
/// Ham değerler iOS'un yazı stilleriyle aynı: "largeTitle", "body" ...
nonisolated enum TextFontStyle: String, Codable, CaseIterable {
    case largeTitle
    case title
    case headline
    case body
    case caption

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .largeTitle: "Büyük"
        case .title: "Başlık"
        case .headline: "Vurgu"
        case .body: "Gövde"
        case .caption: "Küçük"
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.body` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = TextFontStyle(rawValue: rawValue) ?? .body
    }
}
