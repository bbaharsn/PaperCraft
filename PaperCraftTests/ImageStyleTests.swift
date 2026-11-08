//
//  ImageStyleTests.swift
//  PaperCraftTests
//

import Foundation
import SwiftUI
import Testing
import UIKit
@testable import PaperCraft

@MainActor
struct ImageStyleTests {

    @Test func catalogImageHasStyleDefaults() throws {
        let image = try #require(try ComponentCatalog.load().makeElement(of: .image))

        #expect(image.properties.imageName == nil)   // görsel seçilene kadar yer tutucu
        #expect(image.properties.symbolName == "photo")
        #expect(image.properties.imageColorMode == .original)
        #expect(image.properties.tintColor == "#111111")
    }

    @Test func unknownColorModeFallsBackInsteadOfCrashing() throws {
        let json = #"{ "imageName": "hot_beverage", "imageColorMode": "rainbow" }"#
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))

        #expect(properties.imageName == "hot_beverage")
        #expect(properties.imageColorMode == .original)
    }

    @Test func catalogImageStartsFittedWithSquareCorners() throws {
        let image = try #require(try ComponentCatalog.load().makeElement(of: .image))

        #expect(image.properties.contentMode == .fit)
        #expect(image.properties.frameShape == .rectangle)
        #expect(image.properties.cornerRadius == 12)   // "Yuvarlak" seçilince başlangıç değeri
    }

    @Test func unknownContentModeFallsBackToFit() throws {
        let json = #"{ "contentMode": "stretch", "frameShape": "star", "cornerRadius": 20 }"#
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))

        #expect(properties.contentMode == .fit)
        #expect(properties.frameShape == .rounded)
        #expect(properties.cornerRadius == 20)
    }

    @Test func contentModeAndCornerRadiusAreSaved() throws {
        let original = ElementProperties(contentMode: .fill, frameShape: .circle, cornerRadius: 40)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ElementProperties.self, from: data)

        #expect(decoded.contentMode == .fill)
        #expect(decoded.frameShape == .circle)
        #expect(decoded.cornerRadius == 40)
    }

    private let wide = CGRect(x: 0, y: 0, width: 200, height: 100)

    /// Daire, çerçeve kare olmasa da ortadaki karede tam daire çizer.
    @Test func circleIsCenteredInWideFrame() {
        let path = FrameOutline(shape: .circle).path(in: wide)

        #expect(path.boundingRect == CGRect(x: 50, y: 0, width: 100, height: 100))
        #expect(path.contains(CGPoint(x: 100, y: 50)))
        #expect(!path.contains(CGPoint(x: 20, y: 50)))
    }

    @Test func capsuleHasHalfCircleEnds() {
        let path = FrameOutline(shape: .capsule).path(in: wide)

        #expect(!path.contains(CGPoint(x: 3, y: 3)))
        #expect(path.contains(CGPoint(x: 100, y: 2)))
        #expect(path.boundingRect == wide)
    }

    @Test func roundedRadiusStopsAtHalfOfShortSide() {
        let path = FrameOutline(shape: .rounded, cornerRadius: 999).path(in: wide)
        // Kısa kenarın yarısına inince hap ile aynı
        #expect(!path.contains(CGPoint(x: 3, y: 3)))
        #expect(path.contains(CGPoint(x: 100, y: 2)))
    }

    @Test func rectangleKeepsSharpCorners() {
        let path = FrameOutline(shape: .rectangle, cornerRadius: 40).path(in: wide)

        #expect(path.contains(CGPoint(x: 1, y: 1)))
    }

    /// Kenarlık için içeri çekilen daire, aynı merkezde küçülür.
    @Test func insetCircleShrinksAroundCenter() {
        let path = FrameOutline(shape: .circle).inset(by: 10).path(in: wide)

        #expect(path.boundingRect == CGRect(x: 60, y: 10, width: 80, height: 80))
    }

    @Test func libraryLoadsWithUniqueNames() throws {
        let library = try ImageLibrary.load()
        let names = library.images.map(\.name)

        #expect(names.count == 28)
        #expect(Set(names).count == names.count)
        #expect(library.entry(named: "hot_beverage")?.title == "Kahve")
        #expect(library.entry(named: "uydurma_ad") == nil)
    }

    @Test func everyLibraryImageHasBothAssets() throws {
        for image in try ImageLibrary.load().images {
            #expect(UIImage(named: image.name) != nil, "Renkli hali yok: \(image.name)")
            #expect(UIImage(named: image.monoName) != nil, "Tek renk hali yok: \(image.monoName)")
        }
    }

    @Test func pickingImageUpdatesSelectedElement() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .image)

        editor.binding(\.imageName, default: "").wrappedValue = "croissant"
        editor.binding(\.imageColorMode, default: .original).wrappedValue = .mono

        #expect(editor.selectedElement?.properties.imageName == "croissant")
        #expect(editor.selectedElement?.properties.imageColorMode == .mono)
    }
}
