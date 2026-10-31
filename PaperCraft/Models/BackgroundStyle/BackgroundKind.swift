//
//  BackgroundKind.swift
//  PaperCraft
//

import Foundation

/// Arka planın kaç renkten oluştuğu.
nonisolated enum BackgroundKind: String, Codable, CaseIterable {
    case solid
    case twoColors
    case threeColors

    var title: String {
        switch self {
        case .solid: "Düz"
        case .twoColors: "2 Renk"
        case .threeColors: "3 Renk"
        }
    }

    /// Bilinmeyen değer çökmez, düz renge düşer.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = BackgroundKind(rawValue: rawValue) ?? .solid
    }
}
