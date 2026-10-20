//
//  SwitchLabelPosition.swift
//  PaperCraft
//

import Foundation

/// Anahtarın etiketinin yeri; etiketin kendisi `text`'te durur.
/// Etiket istenmiyorsa `text` boş bırakılır, ayrı bir "gizli" seçeneği yok.
nonisolated enum SwitchLabelPosition: String, Codable, CaseIterable {
    /// Etiket solda, anahtar sağda (iOS'un varsayılanı)
    case leading
    /// Anahtar solda, etiket sağda
    case trailing

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .leading: "Solda"
        case .trailing: "Sağda"
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.leading` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = SwitchLabelPosition(rawValue: rawValue) ?? .leading
    }
}
