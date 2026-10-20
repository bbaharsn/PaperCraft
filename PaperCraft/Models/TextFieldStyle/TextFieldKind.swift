//
//  TextFieldKind.swift
//  PaperCraft
//

import Foundation

/// Metin kutusuna ne yazılacağı. Canvas'ta görünüm aynıdır;
/// fark önizleme modunda çıkar (şifre gizlenir, e-posta klavyesi açılır).
nonisolated enum TextFieldKind: String, Codable, CaseIterable {
    case plain
    case secure
    case email

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .plain: "Normal"
        case .secure: "Şifre"
        case .email: "E-posta"
        }
    }

    /// Tanımadığımız bir değer gelirse çökmek yerine `.plain` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = TextFieldKind(rawValue: rawValue) ?? .plain
    }
}
