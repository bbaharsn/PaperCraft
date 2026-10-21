//
//  TextAlign.swift
//  PaperCraft
//

import Foundation

/// Metnin eleman çerçevesi içindeki yatay hizası.
nonisolated enum TextAlign: String, Codable, CaseIterable {
    case leading
    case center
    case trailing

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .leading: "Sola"
        case .center: "Ortaya"
        case .trailing: "Sağa"
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.leading` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = TextAlign(rawValue: rawValue) ?? .leading
    }
}
