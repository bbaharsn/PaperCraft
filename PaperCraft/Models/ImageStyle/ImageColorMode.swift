//
//  ImageColorMode.swift
//  PaperCraft
//

import Foundation

/// Kütüphane görselinin hangi haliyle çizileceği.
nonisolated enum ImageColorMode: String, Codable, CaseIterable {
    /// Görselin kendi renkleri (3D)
    case original
    /// Tek renk; rengi `tintColor`'da durur.
    case mono

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .original: "Renkli"
        case .mono: "Tek renk"
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.original` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = ImageColorMode(rawValue: rawValue) ?? .original
    }
}
