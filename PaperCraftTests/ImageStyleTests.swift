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
