//
//  TextStyleTests.swift
//  PaperCraftTests
//

import Foundation
import SwiftUI
import Testing
@testable import PaperCraft

@MainActor
struct TextStyleTests {

    @Test func catalogTextHasStyleDefaults() throws {
        let text = try #require(try ComponentCatalog.load().makeElement(of: .text))

        #expect(text.properties.text == "Text")
        #expect(text.properties.textStyle == .body)
        #expect(text.properties.fontWeight == .regular)
        #expect(text.properties.fontName == FontFamilies.system)
        #expect(text.properties.isItalic == false)
        #expect(text.properties.textAlignment == .leading)
        #expect(text.properties.contentColor == "#111111")
    }

    @Test func knownTextStyleStillDecodes() throws {
        // Eski kayıtlarda textStyle düz metindi; aynı ham değerler enum'a çevrilmeli
        let json = #"{ "textStyle": "largeTitle" }"#
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))

        #expect(properties.textStyle == .largeTitle)
    }

    @Test func unknownTextValuesFallBackInsteadOfCrashing() throws {
        let json = #"{ "textStyle": "huge", "fontWeight": "black", "textAlignment": "justified" }"#
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))

        #expect(properties.textStyle == .body)
        #expect(properties.fontWeight == .regular)
        #expect(properties.textAlignment == .leading)
    }

    @Test func changingWeightUpdatesSelectedText() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .text)

        editor.binding(\.fontWeight, default: .regular).wrappedValue = .semibold

        #expect(editor.selectedElement?.properties.fontWeight == .semibold)
    }

    @Test func catalogFontFamiliesStartWithSystem() {
        #expect(FontFamilies.all.first == FontFamilies.system)
        #expect(FontFamilies.title(of: FontFamilies.system) == "Sistem")
        #expect(FontFamilies.title(of: "Georgia") == "Georgia")
    }
}
