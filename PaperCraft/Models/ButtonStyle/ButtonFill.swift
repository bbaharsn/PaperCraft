//
//  ButtonFill.swift
//  PaperCraft
//

import Foundation

/// Butonun içinin nasıl boyanacağı.
nonisolated enum ButtonFill: String, Codable, CaseIterable {
    /// İçi tamamen renkli
    case filled
    /// Sadece çerçeve
    case outline
    /// Rengin açık tonu
    case tinted
    /// Arka plan yok, sadece yazı
    case plain

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .filled: "Dolu"
        case .outline: "Çerçeve"
        case .tinted: "Açık"
        case .plain: "Yalın"
        }
    }

    /// Tanımadığımız bir değer gelirse çökmek yerine `.filled` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = ButtonFill(rawValue: rawValue) ?? .filled
    }
}
