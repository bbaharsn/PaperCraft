//
//  TabBarStyleTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import Testing
@testable import PaperCraft

@MainActor
struct TabBarStyleTests {

    /// Boş ekrana bir alt menü ekler ve seçili bırakır (katalogdan 3 sekmeyle gelir).
    private func makeEditorWithTabBar() throws -> EditorViewModel {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .tabBar)
        return editor
    }

    private func properties(_ editor: EditorViewModel) throws -> ElementProperties {
        try #require(editor.selectedElement).properties
    }

    @Test func catalogTabBarHasStyleDefaults() throws {
        let bar = try #require(try ComponentCatalog.load().makeElement(of: .tabBar))

        #expect(bar.properties.items?.count == 3)
        #expect(bar.properties.selectedIndex == 0)
        #expect(bar.properties.showsLabels == true)
        #expect(bar.properties.fillColor == "#F9F9F9")
        #expect(bar.properties.tintColor == "#007AFF")
        #expect(bar.properties.contentColor == "#8E8E93")
        #expect(bar.properties.showsDivider == true)
        #expect(bar.properties.tabBarCorner == .square)
        #expect(bar.properties.isTranslucent == false)
    }

    @Test func unknownTabBarValuesFallBackInsteadOfCrashing() throws {
        let json = #"{ "tabBarCorner": "wavy" }"#
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))

        #expect(properties.tabBarCorner == .square)
    }

    // MARK: - Taşıma ve boyut

    private func rect(_ editor: EditorViewModel) throws -> CGRect {
        editor.pointRect(of: try #require(editor.selectedElement))
    }

    @Test func freeTabBarMovesUp() throws {
        let editor = try makeEditorWithTabBar()
        let id = try #require(editor.selectedElementID)
        let oldTop = try rect(editor).minY

        editor.moveElement(id, dx: 0, dy: -0.1)

        #expect(try rect(editor).minY < oldTop)
    }

    @Test func tabBarCanBeNarrowerThanScreen() throws {
        let editor = try makeEditorWithTabBar()

        editor.setSelectedSize(width: 200, height: 83)

        #expect(abs(try rect(editor).width - 200) < 0.001)
    }

    @Test func addTabStopsAtFive() throws {
        let editor = try makeEditorWithTabBar()

        editor.addSelectedTab()
        #expect(try properties(editor).items?.last == TabItem(text: "Tab 4", symbolName: "star"))

        editor.addSelectedTab()
        editor.addSelectedTab()   // 6. sekme eklenmemeli
        #expect(try properties(editor).items?.count == 5)
    }

    @Test func removeTabStopsAtTwo() throws {
        let editor = try makeEditorWithTabBar()

        editor.removeSelectedTab(at: 0)
        editor.removeSelectedTab(at: 0)   // 2'nin altına inmemeli
        #expect(try properties(editor).items?.map(\.text) == ["Search", "Profile"])

        editor.removeSelectedTab(at: 9)   // olmayan sıra: çökmemeli
        #expect(try properties(editor).items?.count == 2)
    }

    @Test func removingTabKeepsSameTabSelected() throws {
        let editor = try makeEditorWithTabBar()
        editor.addSelectedTab()
        editor.updateSelectedProperties { $0.selectedIndex = 2 }   // "Profile"

        editor.removeSelectedTab(at: 0)

        let after = try properties(editor)
        #expect(after.selectedIndex == 1)
        #expect(after.items?[1].text == "Profile")
    }

    @Test func removingLastSelectedTabSelectsPrevious() throws {
        let editor = try makeEditorWithTabBar()
        editor.updateSelectedProperties { $0.selectedIndex = 2 }

        editor.removeSelectedTab(at: 2)

        #expect(try properties(editor).selectedIndex == 1)
    }

    @Test func updateTabChangesTextAndIcon() throws {
        let editor = try makeEditorWithTabBar()

        editor.updateSelectedTab(at: 1) {
            $0.text = "Ara"
            $0.symbolName = "heart"
        }
        editor.updateSelectedTab(at: 7) { $0.text = "Yok" }   // olmayan sıra: hiçbir şey olmamalı

        let items = try #require(try properties(editor).items)
        #expect(items[1] == TabItem(text: "Ara", symbolName: "heart"))
        #expect(items.count == 3)
    }

    @Test func tabMethodsIgnoreOtherElements() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .button)

        editor.addSelectedTab()

        #expect(try properties(editor).items == nil)
    }
}
