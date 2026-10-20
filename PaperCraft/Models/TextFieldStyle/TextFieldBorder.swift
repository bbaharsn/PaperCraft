//
//  TextFieldBorder.swift
//  PaperCraft
//

import Foundation

/// Metin kutusunun kenarlığı.
nonisolated enum TextFieldBorder: String, Codable, CaseIterable {
    /// Yuvarlak köşeli çerçeve (iOS'un varsayılanı)
    case roundedBorder
    /// Sadece alt çizgi
    case underline
    /// Hap şeklinde çerçeve (arama kutuları gibi)
    case capsule
    /// Kenarlık yok
    case none

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .roundedBorder: "Çerçeve"
        case .underline: "Alt çizgi"
        case .capsule: "Kapsül"
        case .none: "Yok"
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.roundedBorder` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = TextFieldBorder(rawValue: rawValue) ?? .roundedBorder
    }
}
