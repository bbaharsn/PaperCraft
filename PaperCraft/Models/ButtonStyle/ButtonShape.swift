//
//  ButtonShape.swift
//  PaperCraft
//

import Foundation

/// Butonun dış hatları.
nonisolated enum ButtonShape: String, Codable, CaseIterable {
    case rectangle
    case rounded
    case capsule
    case circle

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .rectangle: "Köşeli"
        case .rounded: "Yuvarlak"
        case .capsule: "Hap"
        case .circle: "Daire"
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.rounded` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = ButtonShape(rawValue: rawValue) ?? .rounded
    }
}
