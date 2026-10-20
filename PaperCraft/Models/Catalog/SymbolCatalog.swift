//
//  SymbolCatalog.swift
//  PaperCraft
//

import Foundation

/// `SymbolCatalog.json` dosyasının Swift karşılığı: seçilebilecek SF Symbol'ler.
nonisolated struct SymbolCatalog: Decodable {
    let schemaVersion: Int
    /// Bir sembol bulunamazsa yerine gösterilecek olan.
    let fallbackSymbol: String
    let symbols: [SymbolEntry]

    /// Kataloğu uygulama paketinden (bundle) okur.
    static func load(from bundle: Bundle = .main) throws -> SymbolCatalog {
        guard let url = bundle.url(forResource: "SymbolCatalog", withExtension: "json") else {
            throw ComponentCatalog.LoadError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(SymbolCatalog.self, from: data)
    }

    /// Dosya okunamadığında kullanılan boş katalog (uygulama çökmesin diye).
    static let empty = SymbolCatalog(
        schemaVersion: 1,
        fallbackSymbol: "questionmark.square.dashed",
        symbols: []
    )
}
