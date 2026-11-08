//
//  FrameShape.swift
//  PaperCraft
//

import Foundation

/// Kutunun ve yüklenen fotoğrafın şekli.
nonisolated enum FrameShape: String, Codable, CaseIterable {
    /// Keskin köşeler
    case rectangle
    /// Köşe yuvarlaklığı `cornerRadius`'tan gelir.
    case rounded
    /// Kısa kenarlar tam yarım daire
    case capsule
    /// Çerçeve ne olursa olsun ortada tam daire (profil fotoğrafı, ikon zemini)
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
        self = FrameShape(rawValue: rawValue) ?? .rounded
    }
}
