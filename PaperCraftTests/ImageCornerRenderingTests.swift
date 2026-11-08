//
//  ImageCornerRenderingTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import PaperCraft

/// Yüklenen fotoğrafı gerçekten çizip piksellerine bakar: köşe kırpma ve Sığdır / Doldur ekranda doğru mu?
@MainActor
struct ImageCornerRenderingTests {

    private let store = UploadedImageStore(directory: FileManager.default.temporaryDirectory
        .appending(path: "Image Corner Tests \(UUID().uuidString)"))

    /// 300 × 200 yatay, düz renkli bir "fotoğraf" kaydeder.
    private func saveLandscapePhoto() async throws -> String {
        let context = try #require(CGContext(data: nil, width: 300, height: 200, bitsPerComponent: 8,
                                             bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(red: 0.67, green: 0.32, blue: 0.21, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 300, height: 200))
        let image = try #require(context.makeImage())

        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return try await store.save(data as Data)
    }

    /// Görseli 100 × 100 point'lik çerçevede çizer ve her pikselin opaklığını (0...255) döndürür.
    private func renderAlpha(_ properties: ElementProperties) throws -> (Int, Int) -> UInt8 {
        try render(properties, channel: 3)
    }

    /// Görseli çizer ve her pikselin bir kanalını (0 kırmızı … 3 opaklık) döndürür.
    private func render(_ properties: ElementProperties, channel: Int) throws -> (Int, Int) -> UInt8 {
        let renderer = ImageRenderer(content: ImageElementView(properties: properties, store: store)
            .frame(width: 100, height: 100))
        renderer.scale = 1
        let image = try #require(renderer.cgImage)

        var pixels = [UInt8](repeating: 0, count: 100 * 100 * 4)
        let context = try #require(CGContext(data: &pixels, width: 100, height: 100, bitsPerComponent: 8,
                                             bytesPerRow: 400, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: 100, height: 100))
        // CGContext'in ilk satırı resmin en üstü
        return { x, y in pixels[(y * 100 + x) * 4 + channel] }
    }

    /// Daire, "Sığdır" seçili olsa da fotoğrafla doldurulur. Köşe boş, kenar ortası ve merkez dolu.
    @Test func circleFillsEvenWhenFitIsSelected() async throws {
        let name = try await saveLandscapePhoto()
        let alpha = try renderAlpha(ElementProperties(uploadedImageName: name, contentMode: .fit, frameShape: .circle))

        #expect(alpha(2, 2) == 0)
        #expect(alpha(97, 97) == 0)
        #expect(alpha(50, 2) > 200)
        #expect(alpha(50, 50) > 200)
    }

    /// Sığdır + köşesiz: yatay fotoğraf kare çerçevede üstte ve altta boşluk bırakır.
    @Test func fitLeavesEmptyBandsForLandscapePhoto() async throws {
        let name = try await saveLandscapePhoto()
        let alpha = try renderAlpha(ElementProperties(uploadedImageName: name, contentMode: .fit, frameShape: .rectangle))

        #expect(alpha(50, 5) == 0)
        #expect(alpha(50, 50) > 200)
        #expect(alpha(1, 50) > 200)   // köşesiz: sol kenar dolu
    }

    /// Sığdır + köşe: yuvarlama fotoğrafın görünen kısmına uygulanır, çerçevedeki boşluğa değil.
    @Test func fitRoundsVisiblePhotoCorners() async throws {
        let name = try await saveLandscapePhoto()
        // Görünen kısım 100 × 67, y 17...83 arası
        let alpha = try renderAlpha(ElementProperties(uploadedImageName: name, contentMode: .fit,
                                                      frameShape: .rounded, cornerRadius: 20))

        #expect(alpha(1, 18) == 0)     // görünen kısmın sol üst köşesi kırpıldı
        #expect(alpha(50, 18) > 200)   // üst kenar ortası dolu
    }

    /// Kenarlık dairenin içine çizilir: kenarda siyah, ortada fotoğrafın kendi rengi (kırmızımsı).
    @Test func borderFollowsCircleEdge() async throws {
        let name = try await saveLandscapePhoto()
        let properties = ElementProperties(uploadedImageName: name, frameShape: .circle,
                                           borderWidth: 6, borderColor: "#000000")
        let red = try render(properties, channel: 0)
        let alpha = try renderAlpha(properties)

        #expect(alpha(50, 3) > 200)
        #expect(red(50, 3) < 40)     // kenarlık
        #expect(red(50, 50) > 120)   // fotoğraf
        #expect(alpha(2, 2) == 0)    // daire dışı hâlâ boş
    }

    @Test func noBorderByDefault() async throws {
        let image = try #require(try ComponentCatalog.load().makeElement(of: .image))
        #expect(image.properties.borderWidth == 0)
        #expect(image.properties.borderColor == "#FFFFFF")
    }
}
