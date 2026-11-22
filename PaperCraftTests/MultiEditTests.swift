//
//  MultiEditTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import Testing
@testable import PaperCraft

/// Toplu seçimde aynı türdeki elemanların özelliklerini birlikte düzenleme.
@MainActor
struct MultiEditTests {

    private func element(_ type: ElementType, x: Double, y: Double) -> CanvasElement {
        CanvasElement(type: type, frame: NormalizedFrame(x: x, y: y, width: 0.3, height: 0.06),
                      properties: ElementProperties())
    }

    /// Üç buton ve bir metin; ilk iki buton toplu seçili.
    private func scene() throws -> (EditorViewModel, a: UUID, b: UUID, c: UUID, text: UUID) {
        let a = element(.button, x: 0.1, y: 0.1)
        let b = element(.button, x: 0.1, y: 0.3)
        let c = element(.button, x: 0.1, y: 0.5)
        let text = element(.text, x: 0.1, y: 0.7)
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(),
                                     screen: PrototypeScreen(name: "Test", elements: [a, b, c, text]))
        editor.toggleMultiSelectMode()
        editor.toggleInMultiSelection(a.id)
        editor.toggleInMultiSelection(b.id)
        return (editor, a.id, b.id, c.id, text.id)
    }

    private func properties(_ editor: EditorViewModel, _ id: UUID) -> ElementProperties? {
        editor.screen.elements.first { $0.id == id }?.properties
    }

    @Test func onlySameTypeSelectionCanBeEditedTogether() throws {
        let (editor, _, _, _, text) = try scene()
        #expect(editor.multiSelectionEditType == .button)

        editor.toggleInMultiSelection(text)
        #expect(editor.multiSelectionEditType == nil)

        editor.clearMultiSelection()
        #expect(editor.multiSelectionEditType == nil)
    }

    @Test func changeAppliesToAllSelectedOfThatType() throws {
        let (editor, a, b, c, _) = try scene()
        editor.openMultiSelectionProperties()
        #expect(editor.selectedElementID == a)   // değerler ilk elemandan okunur

        editor.updateSelectedProperties { $0.fillColor = "#34C759" }

        #expect(properties(editor, a)?.fillColor == "#34C759")
        #expect(properties(editor, b)?.fillColor == "#34C759")
        #expect(properties(editor, c)?.fillColor == nil)          // seçili olmayan değişmez
        #expect(editor.undoStack.count == 1)
    }

    @Test func buttonShapeAppliesToAll() throws {
        let (editor, a, b, _, _) = try scene()
        editor.openMultiSelectionProperties()

        editor.setSelectedButtonShape(.circle)

        for id in [a, b] {
            let element = try #require(editor.screen.elements.first { $0.id == id })
            #expect(element.properties.shape == .circle)
            let rect = editor.pointRect(of: element)
            #expect(abs(rect.width - rect.height) < 0.001)
        }
    }

    @Test func closingPropertiesKeepsMultiSelection() throws {
        let (editor, a, b, _, _) = try scene()
        editor.openMultiSelectionProperties()

        editor.closeMultiSelectionProperties()

        #expect(editor.selectedElementID == nil)
        #expect(editor.isMultiSelecting && editor.multiSelection == [a, b])
    }

    /// Sayfa açıkken seçim değişirse: ilk eleman çıkınca değerler sonrakinden okunur,
    /// farklı türden bir eleman eklenince sayfa kapanır.
    @Test func changingSelectionWhileOpenUpdatesOrCloses() throws {
        let (editor, a, b, _, text) = try scene()
        editor.openMultiSelectionProperties()

        editor.toggleInMultiSelection(a)
        #expect(editor.selectedElementID == b)

        editor.toggleInMultiSelection(text)
        #expect(editor.selectedElementID == nil)
    }

    @Test func singleSelectionStillEditsOnlyOne() throws {
        let (editor, a, b, _, _) = try scene()
        editor.toggleMultiSelectMode()   // toplu mod kapanır
        editor.select(a)

        editor.updateSelectedProperties { $0.fillColor = "#34C759" }

        #expect(properties(editor, b)?.fillColor == nil)
    }
}
