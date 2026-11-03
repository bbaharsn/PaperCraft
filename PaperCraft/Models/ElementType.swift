//
//  ElementType.swift
//  PaperCraft
//

import Foundation

/// Canvas üzerinde gösterilebilen arayüz elemanı türleri.
/// Ham değerler `ComponentCatalog.json` içindeki `type` alanlarıyla birebir aynıdır.
nonisolated enum ElementType: String, Codable {
    case text
    case button
    case textField
    case image
    case symbol
    /// Düz bir dikdörtgen: kart zemini, etiket, daire. Üstüne başka elemanlar konur.
    case box
    case `switch`
    case slider
    case navigationBar
    case tabBar
    /// Tanımadığımız bir tür geldiğinde (ör. AI uydurduysa) çökmek yerine buna düşeriz.
    case unknown

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = ElementType(rawValue: rawValue) ?? .unknown
    }
}
