//
//  SymbolEntry.swift
//  PaperCraft
//

import Foundation

/// Sembol kataloğundaki tek bir ikon ve onu bulmaya yarayan anahtar kelimeler.
nonisolated struct SymbolEntry: Decodable {
    let name: String
    let keywords: [String]
}
