//
//  ImageLibraryEntry.swift
//  PaperCraft
//

import Foundation

/// Görsel kütüphanesindeki tek bir görsel.
/// Renkli hali `name`, tek renk hali `name + "_mono"` adıyla Assets'te durur.
nonisolated struct ImageLibraryEntry: Decodable {
    /// Assets'teki adı: "hot_beverage"
    let name: String
    /// Sayfada görünen Türkçe ad: "Kahve"
    let title: String
    let keywords: [String]

    /// Tek renk halinin Assets'teki adı.
    var monoName: String { name + "_mono" }
}
