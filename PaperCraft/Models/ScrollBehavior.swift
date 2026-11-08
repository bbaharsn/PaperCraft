//
//  ScrollBehavior.swift
//  PaperCraft
//

import Foundation

/// Sayfa kayarken üst barın ya da alt menünün ne yapacağı.
nonisolated enum ScrollBehavior: String, Codable, CaseIterable {
    /// Ekranda yerinde durur, içerik altından geçer (çoğu uygulama).
    case fixed
    /// Sayfanın bir parçasıdır, içerikle birlikte kayar.
    case scrolls

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .fixed: "Sabit"
        case .scrolls: "Sayfayla kayar"
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.fixed` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = ScrollBehavior(rawValue: rawValue) ?? .fixed
    }
}
