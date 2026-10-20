//
//  ButtonStyleTests.swift
//  PaperCraftTests
//

import Foundation
import SwiftUI
import Testing
@testable import PaperCraft

@MainActor
struct ButtonStyleTests {

    @Test func catalogButtonHasStyleDefaults() throws {
        let button = try #require(try ComponentCatalog.load().makeElement(of: .button))

        #expect(button.properties.shape == .rounded)
        #expect(button.properties.fill == .filled)
        #expect(button.properties.iconPosition == IconPosition.none)
        #expect(button.properties.fillColor == "#007AFF")
    }

    @Test func unknownStyleValuesFallBackInsteadOfCrashing() throws {
        let json = #"{ "shape": "star", "fill": "glitter", "iconPosition": "top" }"#
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))

        #expect(properties.shape == .rounded)
        #expect(properties.fill == .filled)
        #expect(properties.iconPosition == IconPosition.none)
    }

    @Test func hexStringRoundTrips() throws {
        let color = try #require(Color(hexString: "#AC5135"))
        #expect(color.hexString == "#AC5135")
    }

    @Test func invalidHexStringGivesNil() {
        #expect(Color(hexString: "kırmızı") == nil)
        #expect(Color(hexString: "#FFF") == nil)
    }

    @Test func symbolCatalogLoads() throws {
        let symbols = try SymbolCatalog.load()

        #expect(!symbols.symbols.isEmpty)
        #expect(symbols.fallbackSymbol == "questionmark.square.dashed")
    }
}
