//
//  NavigationTitleMode.swift
//  PaperCraft
//

import Foundation

/// Üst bardaki başlığın türü; iOS'taki `navigationBarTitleDisplayMode` gibi.
nonisolated enum NavigationTitleMode: String, Codable, CaseIterable {
    /// Küçük başlık, butonlarla aynı satırda ortada
    case inline
    /// Büyük başlık, butonların altında solda
    case large

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .inline: "Küçük"
        case .large: "Büyük"
        }
    }

    /// Barın yüksekliği (point). Büyük başlık ikinci bir satır ister.
    var barHeight: Double {
        switch self {
        case .inline: 44
        case .large: 96
        }
    }

    /// Bu türe geçince başlığın yatay yeri: küçük başlık ortada, büyük başlık solda (iOS'taki gibi).
    var defaultAlignment: TextAlign {
        switch self {
        case .inline: .center
        case .large: .leading
        }
    }

    /// Bu türe geçince başlığın dikey yeri: büyük başlık butonların altında, en alta yaslı.
    var defaultVerticalAlignment: VerticalAlign {
        switch self {
        case .inline: .center
        case .large: .bottom
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.inline` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = NavigationTitleMode(rawValue: rawValue) ?? .inline
    }
}
