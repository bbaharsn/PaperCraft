//
//  GradientDirection.swift
//  PaperCraft
//

import Foundation

/// Geçişli arka planın hangi yöne aktığı.
nonisolated enum GradientDirection: String, Codable, CaseIterable {
    case vertical
    case horizontal
    case diagonal

    var title: String {
        switch self {
        case .vertical: "Aşağı"
        case .horizontal: "Yana"
        case .diagonal: "Çapraz"
        }
    }

    /// Bilinmeyen değer çökmez, aşağı doğru geçişe düşer.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = GradientDirection(rawValue: rawValue) ?? .vertical
    }
}
