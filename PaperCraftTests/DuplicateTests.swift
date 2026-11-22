//
//  DuplicateTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import Testing
@testable import PaperCraft

@MainActor
struct DuplicateTests {

    private func makeEditor() throws -> EditorViewModel {
        EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
    }

    /// Normalize ↔ point dönüşümünde küçük yuvarlama farkları olabilir.
    private func isClose(_ a: CGFloat, _ b: CGFloat) -> Bool {
        abs(a - b) < 0.001
    }

    @Test func copyKeepsPropertiesAndIsShifted() throws {
        let editor = try makeEditor()
        editor.addElement(of: .button)
        editor.updateSelectedProperties { $0.text = "Giriş Yap"; $0.fillColor = "#AC5135" }
        let original = try #require(editor.selectedElement)

        editor.duplicateSelectedElement()

        let copy = try #require(editor.selectedElement)
        #expect(copy.id != original.id)
        #expect(copy.properties == original.properties)
        #expect(editor.screen.elements.last?.id == copy.id)   // en üstte ve seçili

        let originalRect = editor.pointRect(of: original)
        let copyRect = editor.pointRect(of: copy)
        #expect(isClose(copyRect.minX, originalRect.minX + 16) && isClose(copyRect.minY, originalRect.minY + 16))
        #expect(isClose(copyRect.width, originalRect.width) && isClose(copyRect.height, originalRect.height))
    }

    /// Kopya yandan taşmaz; aşağıda sayfa uzayabildiği için 16 pt aşağı iner.
    @Test func copyStaysInsideScreenSideways() throws {
        let editor = try makeEditor()
        editor.addElement(of: .button)
        let id = try #require(editor.selectedElementID)
        editor.moveElement(id, dx: 1, dy: 0)   // sağ kenara dayalı
        let original = try #require(editor.selectedElement?.frame)

        editor.duplicateSelectedElement()

        let frame = try #require(editor.selectedElement?.frame)
        #expect(frame.x + frame.width <= 1 + 0.000_001)
        #expect(abs(frame.y - (original.y + 16.0 / 852.0)) < 0.000_001)
    }

    @Test func barsAreNotDuplicated() throws {
        let editor = try makeEditor()
        editor.addElement(of: .navigationBar)
        #expect(!editor.canDuplicateSelected)

        editor.duplicateSelectedElement()

        #expect(editor.screen.elements.count == 1)
    }

    @Test func nothingSelectedDoesNothing() throws {
        let editor = try makeEditor()
        editor.addElement(of: .button)
        editor.select(nil)

        editor.duplicateSelectedElement()

        #expect(editor.screen.elements.count == 1)
    }

    /// Kutu, içinde bir sembol ve kutunun dışında bir buton.
    private func boxEditor() throws -> (EditorViewModel, box: CanvasElement, symbol: CanvasElement) {
        let box = CanvasElement(type: .box, frame: NormalizedFrame(x: 0.1, y: 0.1, width: 0.6, height: 0.2),
                                properties: ElementProperties())
        let symbol = CanvasElement(type: .symbol, frame: NormalizedFrame(x: 0.15, y: 0.15, width: 0.1, height: 0.05),
                                   properties: ElementProperties())
        let button = CanvasElement(type: .button, frame: NormalizedFrame(x: 0.1, y: 0.5, width: 0.4, height: 0.06),
                                   properties: ElementProperties())
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(),
                                     screen: PrototypeScreen(name: "Test", elements: [box, symbol, button]))
        return (editor, box, symbol)
    }

    @Test func duplicatingBoxCopiesItsContents() throws {
        let (editor, box, symbol) = try boxEditor()
        editor.select(box.id)

        editor.duplicateSelectedElement()

        #expect(editor.screen.elements.count == 5)
        let copyBox = try #require(editor.selectedElement)
        #expect(copyBox.id != box.id && copyBox.type == .box)
        // Kopyalar en üstte, kutu içindekinden önce: içindekiler yeni kutunun içinde sayılır
        let topTwo = editor.screen.elements.suffix(2)
        #expect(topTwo.first?.id == copyBox.id)
        let copySymbol = try #require(topTwo.last)
        #expect(copySymbol.id != symbol.id && copySymbol.type == .symbol)
        #expect(editor.movingGroup(for: [copyBox.id]) == [copyBox.id, copySymbol.id])

        // İkisi de aynı 16 pt kayar
        let symbolRect = editor.pointRect(of: symbol), copyRect = editor.pointRect(of: copySymbol)
        #expect(isClose(copyRect.minX, symbolRect.minX + 16) && isClose(copyRect.minY, symbolRect.minY + 16))
    }

    @Test func duplicatingBoxIsOneUndoStep() throws {
        let (editor, box, _) = try boxEditor()
        editor.select(box.id)
        let before = editor.screen

        editor.duplicateSelectedElement()
        #expect(editor.undoStack.count == 1)
        editor.undo()

        #expect(editor.screen == before)
    }

    /// Sağ kenara dayalı kutu: grup tek parça sınırlanır, içindekinin kutudaki yeri değişmez.
    @Test func duplicatedBoxAtEdgeKeepsContentsInside() throws {
        let (editor, box, _) = try boxEditor()
        editor.select(box.id)
        editor.moveGroup(editor.movingGroup(for: [box.id]), dx: 1, dy: 0)   // sağ kenara dayalı

        editor.duplicateSelectedElement()

        let copyBox = try #require(editor.selectedElement)
        #expect(copyBox.frame.x + copyBox.frame.width <= 1 + 0.000_001)
        #expect(editor.movingGroup(for: [copyBox.id]).count == 2)
    }

    @Test func undoRemovesCopy() throws {
        let editor = try makeEditor()
        var date = Date(timeIntervalSince1970: 0)
        editor.now = { date }
        editor.addElement(of: .button)
        date += EditorViewModel.mergeInterval + 1

        editor.duplicateSelectedElement()
        editor.undo()

        #expect(editor.screen.elements.count == 1)
    }
}
