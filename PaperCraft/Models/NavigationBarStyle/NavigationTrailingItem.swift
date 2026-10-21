//
//  NavigationTrailingItem.swift
//  PaperCraft
//

import Foundation

/// Üst barın sağındaki buton; ikon `symbolName`'de, yazı `trailingText`'te durur.
nonisolated enum NavigationTrailingItem: String, Codable, CaseIterable {
    case none
    case icon
    case text

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .none: "Yok"
        case .icon: "İkon"
        case .text: "Yazı"
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.none` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = NavigationTrailingItem(rawValue: rawValue) ?? .none
    }
}
