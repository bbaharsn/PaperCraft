//
//  TextWeight.swift
//  PaperCraft
//

import Foundation

/// Metnin kalınlığı.
nonisolated enum TextWeight: String, Codable, CaseIterable {
    case regular
    case medium
    case semibold
    case bold

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .regular: "Normal"
        case .medium: "Orta"
        case .semibold: "Yarı kalın"
        case .bold: "Kalın"
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.regular` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = TextWeight(rawValue: rawValue) ?? .regular
    }
}
