//
//  UploadedImageStore.swift
//  PaperCraft
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Kullanıcının yüklediği fotoğrafları uygulamanın klasöründe PNG olarak saklar.
/// Modelde sadece dosya adı tutulur ("8F3A….png"); görselin kendisi JSON'a yazılmaz.
final class UploadedImageStore {
    static let shared = UploadedImageStore()

    enum StoreError: Error {
        /// Veri bir görsel değil ya da açılamadı
        case unreadableImage
        /// PNG dosyası yazılamadı
        case writeFailed
    }

    /// Fotoğrafın uzun kenarı en fazla bu kadar piksel olur; dosyalar küçük, canvas akıcı kalır.
    nonisolated static let maxPixelSize = 2048

    let directory: URL
    /// Her çizimde dosyadan okumamak için açılan görseller burada tutulur.
    private var cache: [String: CGImage] = [:]

    init(directory: URL = URL.applicationSupportDirectory.appending(path: "UploadedImages")) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Seçilen fotoğrafı (HEIC, JPEG, PNG…) küçültüp PNG olarak kaydeder ve dosya adını döner.
    func save(_ data: Data) async throws -> String {
        let name = UUID().uuidString + ".png"
        try await Self.writePNG(from: data, to: directory.appending(path: name))
        return name
    }

    /// Arka planı silinmiş halin dosya adı: "8F3A….png" → "8F3A…_nobg.png"
    static func backgroundRemovedName(for name: String) -> String {
        name.replacingOccurrences(of: ".png", with: "_nobg.png")
    }

    /// Arka planı silinmiş hali daha önce hazırlandı mı.
    func hasBackgroundRemoved(for name: String) -> Bool {
        FileManager.default.fileExists(atPath: directory.appending(path: Self.backgroundRemovedName(for: name))
            .path(percentEncoded: false))
    }

    /// Fotoğrafın arka planı silinmiş halini hazırlayıp yanına kaydeder.
    /// Fotoğrafta ayrılacak bir nesne bulunamazsa `false` döner.
    func makeBackgroundRemoved(for name: String) async throws -> Bool {
        try await Self.writeBackgroundRemoved(from: directory.appending(path: name),
                                              to: directory.appending(path: Self.backgroundRemovedName(for: name)))
    }

    /// Kayıtlı görsel; dosya yoksa (ör. silindiyse ya da ad uydurulduysa) `nil`.
    func image(named name: String) -> CGImage? {
        if let cached = cache[name] { return cached }
        guard let source = CGImageSourceCreateWithURL(directory.appending(path: name) as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        cache[name] = image
        return image
    }

    /// Hiçbir elemanın kullanmadığı fotoğrafları (ve arka plansız hallerini) siler.
    /// Geri al ile dönen eleman dosyasını bulamasın diye silme anında değil, uygulama açılınca çağrılır.
    func removeUnused(keeping usedNames: Set<String>) {
        let kept = usedNames.union(usedNames.map(Self.backgroundRemovedName(for:)))
        // `path()` boşluğu "%20" yapar; "Application Support" klasörü öyle bulunamaz
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))) ?? []
        for name in files where !kept.contains(name) {
            try? FileManager.default.removeItem(at: directory.appending(path: name))
            cache[name] = nil
        }
    }

    // MARK: - Ağır işler (ana thread'i dondurmasın diye arka planda)

    @concurrent
    nonisolated private static func writePNG(from data: Data, to url: URL) async throws {
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,   // telefonda çekilen fotoğrafın yönünü düzeltir
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            throw StoreError.unreadableImage
        }
        try write(image, to: url)
    }

    @concurrent
    nonisolated private static func writeBackgroundRemoved(from source: URL, to target: URL) async throws -> Bool {
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw StoreError.unreadableImage
        }
        guard let cutout = try BackgroundRemover.removeBackground(from: image) else { return false }
        try write(cutout, to: target)
        return true
    }

    nonisolated private static func write(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw StoreError.writeFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw StoreError.writeFailed }
    }
}
