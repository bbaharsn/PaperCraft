//
//  RenderedPixels.swift
//  PaperCraftTests
//

import CoreGraphics
import SwiftUI
import Testing

/// Bir SwiftUI görünümünü verilen boyutta (1 point = 1 piksel) çizer ve piksellerini okutur.
/// Görünüşü değiştiren özelliklerin (şekil, kenarlık, kırpma) ekranda gerçekten doğru çizildiğini test etmek için.
@MainActor
struct RenderedPixels {
    let width: Int
    let height: Int
    private let bytes: [UInt8]

    init(_ view: some View, width: Int, height: Int) throws {
        let renderer = ImageRenderer(content: view.frame(width: CGFloat(width), height: CGFloat(height)))
        renderer.scale = 1
        let image = try #require(renderer.cgImage)

        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let context = try #require(CGContext(data: &bytes, width: width, height: height, bitsPerComponent: 8,
                                             bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        self.width = width
        self.height = height
        self.bytes = bytes
    }

    /// Opaklık, 0 (boş) … 255 (tam dolu). (0, 0) sol üst köşe.
    func alpha(_ x: Int, _ y: Int) -> UInt8 { channel(3, x, y) }
    /// Kırmızı kanal (opaklıkla çarpılmış).
    func red(_ x: Int, _ y: Int) -> UInt8 { channel(0, x, y) }

    private func channel(_ index: Int, _ x: Int, _ y: Int) -> UInt8 {
        bytes[(y * width + x) * 4 + index]
    }
}
