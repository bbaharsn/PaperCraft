//
//  IconPosition.swift
//  PaperCraft
//

import Foundation

/// Butondaki ikonun yazıya göre yeri.
nonisolated enum IconPosition: String, Codable, CaseIterable {
    case none
    case leading
    case trailing

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .none: "Yok"
        case .leading: "Solda"
        case .trailing: "Sağda"
        }
    }

    /// Tanımadığımız bir değer gelirse çökmek yerine `.none` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = IconPosition(rawValue: rawValue) ?? .none
    }
}
