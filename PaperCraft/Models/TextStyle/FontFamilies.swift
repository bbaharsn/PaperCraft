//
//  FontFamilies.swift
//  PaperCraft
//

import Foundation

/// Metin için seçilebilen yazı tipi aileleri.
/// Hepsi hem iOS'ta hem macOS'ta yüklü gelir; ek dosya gerekmez.
nonisolated enum FontFamilies {
    /// Sistem yazı tipi (San Francisco) için kullanılan ad.
    static let system = "System"

    static let all = [
        system,
        // Sans serif
        "Helvetica Neue",
        "Avenir Next",
        "Futura",
        "Gill Sans",
        "Optima",
        // Serif
        "Georgia",
        "Times New Roman",
        "Baskerville",
        "Palatino",
        "Didot",
        "Copperplate",
        // Daktilo / kod
        "American Typewriter",
        "Courier New",
        "Menlo",
        // El yazısı / eğlenceli
        "Chalkboard SE",
        "Marker Felt",
        "Noteworthy",
        "Snell Roundhand",
    ]

    /// Sayfada görünen ad; sistem yazı tipi "Sistem" olarak yazılır.
    static func title(of name: String) -> String {
        name == system ? "Sistem" : name
    }
}
