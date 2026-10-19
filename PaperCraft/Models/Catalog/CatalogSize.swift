//
//  CatalogSize.swift
//  PaperCraft
//

import Foundation

/// Katalogdaki boyutlar, referans ekrana göre **point** cinsindendir (normalize değil).
nonisolated struct CatalogSize: Decodable {
    let width: Double
    let height: Double
}
