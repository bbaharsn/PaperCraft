//
//  ScreenBackground.swift
//  PaperCraft
//

import Foundation

/// Bir sayfanın arka planı: düz renk ya da iki veya üç renkli geçiş.
/// Tür değişince diğer renkler ve yön silinmez; geri dönülünce aynen gelir.
nonisolated struct ScreenBackground: Codable, Equatable {
    /// Kağıt rengi; arka planı değiştirilmemiş sayfalar bu renkte görünür.
    static let defaultColor = "#FBF7EE"

    var kind = BackgroundKind.solid
    /// Düz renk ya da geçişin başlangıç rengi.
    var color = Self.defaultColor
    /// Sadece üç renkli geçişte kullanılır.
    var middleColor = "#FFD6E0"
    var endColor = "#F4C6A8"
    var direction = GradientDirection.vertical

    /// Çizilecek renkler, sırayla. Tek renk varsa düz, fazlası geçiştir.
    var colors: [String] {
        switch kind {
        case .solid: [color]
        case .twoColors: [color, endColor]
        case .threeColors: [color, middleColor, endColor]
        }
    }
}

extension ScreenBackground {
    /// Eksik alanlar varsayılana düşer; JSON ileride AI'dan da gelebilir.
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ScreenBackground()
        kind = try container.decodeIfPresent(BackgroundKind.self, forKey: .kind) ?? defaults.kind
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? defaults.color
        middleColor = try container.decodeIfPresent(String.self, forKey: .middleColor) ?? defaults.middleColor
        endColor = try container.decodeIfPresent(String.self, forKey: .endColor) ?? defaults.endColor
        direction = try container.decodeIfPresent(GradientDirection.self, forKey: .direction) ?? defaults.direction
    }
}
