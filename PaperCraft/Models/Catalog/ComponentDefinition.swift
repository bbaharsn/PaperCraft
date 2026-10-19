//
//  ComponentDefinition.swift
//  PaperCraft
//

import Foundation

/// Katalogdaki tek bir bileşenin tanımı: "bir buton varsayılan olarak nasıl görünür?"
nonisolated struct ComponentDefinition: Decodable {
    let type: ElementType
    let displayName: String
    let category: String
    /// Eleman Kütüphanesi'nde (palette) gösterilecek SF Symbol.
    let paletteSymbol: String
    let placement: ComponentPlacement
    let defaultSize: CatalogSize
    let minSize: CatalogSize
    let defaultProperties: ElementProperties
    /// AI'ın bu bileşen için kullanabileceği alternatif adlar (ileride parser kullanacak).
    let aiAliases: [String]
}
