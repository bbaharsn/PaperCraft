//
//  NavigationBarStyleTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import PaperCraft

@MainActor
struct NavigationBarStyleTests {

    /// Boş ekrana bir üst bar ekler ve seçili bırakır.
    private func makeEditorWithBar() throws -> EditorViewModel {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .navigationBar)
        return editor
    }

    private func barHeight(_ editor: EditorViewModel) throws -> CGFloat {
        editor.pointRect(of: try #require(editor.selectedElement)).height
    }

    @Test func catalogNavigationBarHasStyleDefaults() throws {
        let bar = try #require(try ComponentCatalog.load().makeElement(of: .navigationBar))

        #expect(bar.properties.titleDisplayMode == .inline)
        #expect(bar.properties.showsBackButton == false)
        #expect(bar.properties.backTitle == "")   // varsayılan: sadece ok
        #expect(bar.properties.fontName == FontFamilies.system)
        #expect(bar.properties.trailingItem == NavigationTrailingItem.none)
        #expect(bar.properties.symbolName == "plus")
        #expect(bar.properties.fillColor == "#F9F9F9")
        #expect(bar.properties.contentColor == "#111111")
        #expect(bar.properties.tintColor == "#007AFF")
        #expect(bar.properties.showsDivider == true)
        #expect(bar.properties.textAlignment == .center)
        #expect(bar.properties.verticalAlignment == .center)
    }

    @Test func titleModeResetsTitlePosition() throws {
        let editor = try makeEditorWithBar()

        editor.setSelectedNavigationTitleMode(.large)
        #expect(editor.selectedElement?.properties.textAlignment == .leading)
        #expect(editor.selectedElement?.properties.verticalAlignment == .bottom)

        editor.setSelectedNavigationTitleMode(.inline)
        #expect(editor.selectedElement?.properties.textAlignment == .center)
        #expect(editor.selectedElement?.properties.verticalAlignment == .center)
    }

    @Test func unknownNavigationValuesFallBackInsteadOfCrashing() throws {
        let json = #"{ "titleDisplayMode": "automatic", "trailingItem": "menu", "verticalAlignment": "middle" }"#
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))

        #expect(properties.verticalAlignment == .center)
        #expect(properties.titleDisplayMode == .inline)
        #expect(properties.trailingItem == NavigationTrailingItem.none)
    }

    @Test func largeTitleGrowsBarAndInlineShrinksIt() throws {
        let editor = try makeEditorWithBar()
        #expect(abs(try barHeight(editor) - 44) < 0.001)

        editor.setSelectedNavigationTitleMode(.large)
        #expect(editor.selectedElement?.properties.titleDisplayMode == .large)
        #expect(abs(try barHeight(editor) - 96) < 0.001)

        editor.setSelectedNavigationTitleMode(.inline)
        #expect(abs(try barHeight(editor) - 44) < 0.001)
    }

    @Test func largeTitleBarCannotBeSquashed() throws {
        let editor = try makeEditorWithBar()
        editor.setSelectedNavigationTitleMode(.large)

        editor.setSelectedSize(width: 393, height: 50)

        #expect(abs(try barHeight(editor) - 96) < 0.001)
    }

    @Test func titleModeIgnoresOtherElements() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .button)

        editor.setSelectedNavigationTitleMode(.large)

        #expect(editor.selectedElement?.properties.titleDisplayMode == nil)
    }
}
