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

    @Test func changingBoxColorUpdatesSelectedBox() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .box)

        editor.binding(\.fillColor, default: "#FFFFFF").wrappedValue = "#F27A1A"
        editor.binding(\.hasShadow, default: false).wrappedValue = true

        #expect(editor.selectedElement?.properties.fillColor == "#F27A1A")
        #expect(editor.selectedElement?.properties.hasShadow == true)
    }
}
