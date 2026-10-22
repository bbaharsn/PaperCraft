//
//  TabBarCorner.swift
//  PaperCraft
//

import Foundation

/// Alt menünün köşeleri.
nonisolated enum TabBarCorner: String, Codable, CaseIterable {
    case square
    case rounded
    case capsule

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .square: "Köşeli"
        case .rounded: "Yuvarlak"
        case .capsule: "Hap"
        }
    }

    /// Çizim ve seçim çizgisi butonla aynı şekilleri kullanır.
    var buttonShape: ButtonShape {
        switch self {
        case .square: .rectangle
        case .rounded: .rounded
        case .capsule: .capsule
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.square` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = TabBarCorner(rawValue: rawValue) ?? .square
    }
}
