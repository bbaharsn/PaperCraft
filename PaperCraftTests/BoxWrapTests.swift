//
//  BoxWrapTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import PaperCraft

@MainActor
struct BoxWrapTests {

    private func element(_ type: ElementType, x: Double, y: Double, width: Double, height: Double) -> CanvasElement {
        CanvasElement(type: type, frame: NormalizedFrame(x: x, y: y, width: width, height: height),
                      properties: ElementProperties())
    }

    private func editor(_ elements: [CanvasElement]) throws -> EditorViewModel {
        EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test", elements: elements))
    }

    // MARK: - Kutuya al

    @Test func wrapAddsWhiteBoxBehindSelectionThatCarriesIt() throws {
        let title = element(.text, x: 0.1, y: 0.2, width: 0.5, height: 0.05)
        let other = element(.button, x: 0.1, y: 0.7, width: 0.4, height: 0.06)
        let field = element(.textField, x: 0.1, y: 0.27, width: 0.8, height: 0.06)
        let editor = try editor([title, other, field])
        editor.toggleMultiSelectMode()
        editor.toggleInMultiSelection(title.id)
        editor.toggleInMultiSelection(field.id)

        let boxID = try #require(editor.wrapMultiSelectionInBox())
        let ids = editor.screen.elements.map(\.id)
        #expect(ids == [other.id, boxID, title.id, field.id])

        let box = try #require(editor.screen.elements.first { $0.id == boxID })
        #expect(box.type == .box && box.properties.fillColor == "#FFFFFF")
        // Kutu taşınınca seçilenler gelir, dışarıdaki buton gelmez
        #expect(editor.movingGroup(for: [boxID]) == [boxID, title.id, field.id])

        #expect(!editor.isMultiSelecting && editor.multiSelection.isEmpty)
        #expect(editor.selectedElementID == boxID)
    }

    @Test func wrapLeavesPaddingAndStaysOnPage() throws {
        // Sol kenara yapışık eleman: kutu sayfanın solundan taşmaz
        let edge = element(.text, x: 0, y: 0.3, width: 0.5, height: 0.05)
        let editor = try editor([edge])
        editor.toggleMultiSelectMode()
        editor.toggleInMultiSelection(edge.id)
        let boxID = try #require(editor.wrapMultiSelectionInBox(padding: 16))
        let rect = editor.pointRect(of: try #require(editor.screen.elements.first { $0.id == boxID }))
        let inner = editor.pointRect(of: edge)

        #expect(abs(rect.minX) < 0.001)
        #expect(abs(rect.maxX - (inner.maxX + 16)) < 0.001)
        #expect(abs(rect.minY - (inner.minY - 16)) < 0.001)
        #expect(abs(rect.maxY - (inner.maxY + 16)) < 0.001)
    }

    @Test func wrapIsOneUndoStep() throws {
        let symbol = element(.symbol, x: 0.3, y: 0.3, width: 0.1, height: 0.05)
        let editor = try editor([symbol])
        editor.toggleMultiSelectMode()
        editor.toggleInMultiSelection(symbol.id)
        editor.wrapMultiSelectionInBox()
        #expect(editor.screen.elements.count == 2)
        editor.undo()
        #expect(editor.screen.elements.map(\.id) == [symbol.id])
    }

    @Test func wrapWithEmptySelectionDoesNothing() throws {
        let editor = try editor([element(.symbol, x: 0.3, y: 0.3, width: 0.1, height: 0.05)])
        editor.toggleMultiSelectMode()
        #expect(editor.wrapMultiSelectionInBox() == nil)
        #expect(editor.screen.elements.count == 1 && !editor.canUndo)
    }

    // MARK: - Sayfa arka planıyla aynı

    @Test func catalogBoxUsesItsOwnColorByDefault() throws {
        let box = try #require(try ComponentCatalog.load().makeElement(of: .box))
        #expect(box.properties.matchesPageBackground == false)
    }

    @Test func oldSavesWithoutTheFieldStillOpen() throws {
        let json = ##"{ "fillColor": "#FFFFFF", "cornerRadius": 12 }"##
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))
        #expect(properties.matchesPageBackground == nil)
    }

    @Test func matchingBoxShowsSolidPageColor() throws {
        let box = BoxElementView(properties: ElementProperties(fillColor: "#FFFFFF", borderWidth: 0,
                                                               matchesPageBackground: true))
        let page = ZStack { box.frame(width: 40, height: 40) }
            .frame(width: 60, height: 60)
            .pageBackdrop(ScreenBackground(color: "#FF0000"), size: CGSize(width: 60, height: 60))
        let pixels = try RenderedPixels(page, width: 60, height: 60)
        #expect(pixels.red(30, 30) > 240)
    }

    @Test func matchingBoxShowsItsPartOfTheGradient() throws {
        // Yukarıdan aşağı siyahtan beyaza geçiş; kutu sayfanın altında, kendi yerindeki açık rengi göstermeli
        let background = ScreenBackground(kind: .twoColors, color: "#000000", endColor: "#FFFFFF")
        let box = BoxElementView(properties: ElementProperties(frameShape: .rectangle, borderWidth: 0,
                                                               matchesPageBackground: true))
        let page = ZStack(alignment: .topLeading) {
            Color.clear
            box.frame(width: 40, height: 20).offset(x: 10, y: 170)
        }
        .frame(width: 60, height: 200)
        .pageBackdrop(background, size: CGSize(width: 60, height: 200))
        let pixels = try RenderedPixels(page, width: 60, height: 200)
        // y = 180 → geçişin %90'ı: açık renk. Bütün geçiş kutuya sıkıştırılsaydı ortası gri (~128) olurdu.
        #expect(pixels.red(30, 180) > 200)
    }
}
