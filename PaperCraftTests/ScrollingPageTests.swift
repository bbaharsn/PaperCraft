//
//  ScrollingPageTests.swift
//  PaperCraftTests
//

import Foundation
import Testing
@testable import PaperCraft

@MainActor
struct ScrollingPageTests {

    private func element(_ type: ElementType = .box, y: Double, height: Double = 0.1,
                         scroll: ScrollBehavior? = nil) -> CanvasElement {
        CanvasElement(type: type, frame: NormalizedFrame(x: 0.1, y: y, width: 0.5, height: height),
                      properties: ElementProperties(scrollBehavior: scroll))
    }

    private func screen(_ elements: [CanvasElement]) -> PrototypeScreen {
        PrototypeScreen(name: "Test", elements: elements)
    }

    private func editor(_ elements: [CanvasElement] = []) throws -> EditorViewModel {
        EditorViewModel(catalog: try ComponentCatalog.load(), screen: screen(elements))
    }

    // MARK: - Sayfanın uzunluğu

    @Test func emptyPageIsOneScreen() {
        #expect(screen([]).contentHeight == 1)
    }

    @Test func shortPageIsOneScreen() {
        #expect(screen([element(y: 0.7)]).contentHeight == 1)
    }

    @Test func longPageEndsBelowLowestElement() {
        let page = screen([element(y: 0.2), element(y: 1.5)])
        #expect(abs(page.contentHeight - (1.6 + 24.0 / 852.0)) < 0.0001)
    }

    @Test func pinnedBarsDoNotCount() {
        let page = screen([element(.tabBar, y: 0.9), element(y: 1.2)])
        #expect(abs(page.contentHeight - (1.3 + PrototypeScreen.endMargin)) < 0.0001)
    }

    @Test func scrollingBarCounts() {
        let page = screen([element(.navigationBar, y: 1.4, scroll: .scrolls)])
        #expect(abs(page.contentHeight - (1.5 + PrototypeScreen.endMargin)) < 0.0001)
    }

    @Test func onlyFixedBarsArePinned() {
        #expect(element(.navigationBar, y: 0).isPinned)
        #expect(element(.tabBar, y: 0.9, scroll: .fixed).isPinned)
        #expect(!element(.tabBar, y: 0.9, scroll: .scrolls).isPinned)
        #expect(!element(.box, y: 0).isPinned)
    }

    @Test func catalogBarsAreFixed() throws {
        let catalog = try ComponentCatalog.load()
        #expect(catalog.makeElement(of: .navigationBar)?.properties.scrollBehavior == .fixed)
        #expect(catalog.makeElement(of: .tabBar)?.properties.scrollBehavior == .fixed)
    }

    @Test func unknownScrollBehaviorFallsBackToFixed() throws {
        let json = #"{ "scrollBehavior": "bounce" }"#
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))
        #expect(properties.scrollBehavior == .fixed)
    }

    // MARK: - Editör

    @Test func addedElementLandsInVisibleArea() throws {
        let editor = try editor()
        editor.visibleTop = 2
        editor.addElement(of: .box)

        let frame = try #require(editor.selectedElement?.frame)
        #expect(abs(frame.y - (2 + (1 - frame.height) / 2)) < 0.0001)
    }

    @Test func addedBarIgnoresScroll() throws {
        let editor = try editor()
        editor.visibleTop = 2
        editor.addElement(of: .navigationBar)

        #expect(editor.selectedElement?.frame.y == 0)
    }

    @Test func freeElementMovesBelowFirstScreen() throws {
        let box = element(y: 0.5)
        let editor = try editor([box])
        editor.moveElement(box.id, dx: 0, dy: 1.5)

        #expect(abs((editor.screen.elements[0].frame.y) - 2.0) < 0.0001)
    }

    @Test func freeElementStopsAtTop() throws {
        let box = element(y: 0.5)
        let editor = try editor([box])
        editor.moveElement(box.id, dx: 0, dy: -3)

        #expect(editor.screen.elements[0].frame.y == 0)
    }

    @Test func pinnedBarStaysInsideViewport() throws {
        let bar = element(.tabBar, y: 0.9)
        let editor = try editor([bar])
        editor.moveElement(bar.id, dx: 0, dy: 2)

        #expect(abs(editor.screen.elements[0].frame.y - 0.9) < 0.0001)
    }

    @Test func resizeGrowsBelowFirstScreen() throws {
        let box = element(y: 0.95)
        let editor = try editor([box])
        editor.resizeElement(box.id, from: .bottomTrailing, by: CGSize(width: 0, height: 200))

        let frame = editor.screen.elements[0].frame
        #expect(frame.y + frame.height > 1)
    }

    @Test func duplicateBelowFirstScreenIsNotClamped() throws {
        let box = element(y: 1.8)
        let editor = try editor([box])
        editor.select(box.id)
        editor.duplicateSelectedElement()

        let copy = try #require(editor.selectedElement)
        #expect(copy.frame.y > 1.8)
    }

    @Test func undoRestoresElementBelowFirstScreen() throws {
        let box = element(y: 1.5)
        let editor = try editor([box])
        editor.moveElement(box.id, dx: 0, dy: 0.5)
        editor.undo()

        #expect(abs(editor.screen.elements[0].frame.y - 1.5) < 0.0001)
    }
}
