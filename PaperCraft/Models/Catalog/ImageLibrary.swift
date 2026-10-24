//
//  ImageLibrary.swift
//  PaperCraft
//

import Foundation

/// `ImageLibrary.json` dosyasının Swift karşılığı: uygulamayla gelen hazır görseller.
/// Görseller Microsoft Fluent Emoji'den (MIT, `Resources/Licenses`).
nonisolated struct ImageLibrary: Decodable {
    let schemaVersion: Int
    let images: [ImageLibraryEntry]

    /// Adı verilen görsel; kütüphanede yoksa (ör. AI uydurduysa) `nil`.
    func entry(named name: String) -> ImageLibraryEntry? {
        images.first { $0.name == name }
    }

    /// Kütüphaneyi uygulama paketinden (bundle) okur.
    static func load(from bundle: Bundle = .main) throws -> ImageLibrary {
        guard let url = bundle.url(forResource: "ImageLibrary", withExtension: "json") else {
            throw ComponentCatalog.LoadError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ImageLibrary.self, from: data)
    }

    /// Dosya okunamadığında kullanılan boş kütüphane (uygulama çökmesin diye).
    static let empty = ImageLibrary(schemaVersion: 1, images: [])
}
