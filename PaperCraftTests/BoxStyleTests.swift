//
//  BoxStyleTests.swift
//  PaperCraftTests
//

import Foundation
import SwiftUI
import Testing
@testable import PaperCraft

@MainActor
struct BoxStyleTests {

    @Test func catalogBoxHasStyleDefaults() throws {
        let box = try #require(try ComponentCatalog.load().makeElement(of: .box))

        #expect(box.type == .box)
        #expect(box.properties.fillColor == "#FFFFFF")
        #expect(box.properties.frameShape == .rounded)
        #expect(box.properties.cornerRadius == 12)
        #expect(box.properties.borderWidth == 1)
        #expect(box.properties.borderColor == "#E5E5EA")
        #expect(box.properties.hasShadow == false)
    }

    @Test func boxSurvivesSaveAndLoad() throws {
        var box = try #require(try ComponentCatalog.load().makeElement(of: .box))
        box.properties.cornerRadius = 30
        box.properties.borderWidth = 0
        box.properties.hasShadow = true

        let loaded = try JSONDecoder().decode(CanvasElement.self, from: JSONEncoder().encode(box))

        #expect(loaded.type == .box)
        #expect(loaded.properties == box.properties)
    }

    @Test func cornerRadiusStopsAtHalfOfShortSide() {
        let size = CGSize(width: 100, height: 40)

        #expect(BoxElementView.clampedRadius(12, in: size) == 12)
        #expect(BoxElementView.clampedRadius(99, in: size) == 20)
        #expect(BoxElementView.clampedRadius(-5, in: size) == 0)
    }

    /// Şekil seçimi gelmeden önce kaydedilmiş kutu (frameShape yok) eskisi gibi yuvarlak açılır.
    @Test func boxSavedBeforeShapesStaysRounded() throws {
        let json = ##"{ "fillColor": "#F27A1A", "cornerRadius": 99 }"##
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))

        #expect(properties.frameShape == nil)
        let path = FrameOutline(shape: properties.frameShape ?? .rounded, cornerRadius: properties.cornerRadius ?? 12)
            .path(in: CGRect(x: 0, y: 0, width: 60, height: 60))
        #expect(!path.contains(CGPoint(x: 3, y: 3)))   // köşe hâlâ yuvarlak (daire)
    }

    /// Daire kutu geniş çerçevede ortada çizilir: yanlar boş, orta dolu.
    @Test func circleBoxRendersCenteredCircle() throws {
        let view = BoxElementView(properties: ElementProperties(fillColor: "#25D366", frameShape: .circle, borderWidth: 0))
            .frame(width: 200, height: 100)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let image = try #require(renderer.cgImage)

        var pixels = [UInt8](repeating: 0, count: 200 * 100 * 4)
        let context = try #require(CGContext(data: &pixels, width: 200, height: 100, bitsPerComponent: 8,
                                             bytesPerRow: 800, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: 200, height: 100))
        func alpha(_ x: Int, _ y: Int) -> UInt8 { pixels[(y * 200 + x) * 4 + 3] }

        #expect(alpha(100, 50) > 200)
        #expect(alpha(20, 50) == 0)
        #expect(alpha(180, 50) == 0)
        #expect(alpha(52, 3) == 0)   // dairenin dışındaki kare köşesi
    }

    @Test func changingBoxColorUpdatesSelectedBox() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .box)

        editor.binding(\.fillColor, default: "#FFFFFF").wrappedValue = "#F27A1A"
        editor.binding(\.hasShadow, default: false).wrappedValue = true

        #expect(editor.selectedElement?.properties.fillColor == "#F27A1A")
        #expect(editor.selectedElement?.properties.hasShadow == true)
    }
}
