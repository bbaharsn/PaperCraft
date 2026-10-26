//
//  UndoTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import Testing
@testable import PaperCraft

@MainActor
struct UndoTests {

    /// Saati elle ilerletilen bir editör: her değişiklik "ayrı bir an" sayılsın diye.
    private final class Clock {
        var date = Date(timeIntervalSince1970: 0)
        /// Birleştirme süresinden uzun bir bekleme
        func pause() { date += EditorViewModel.mergeInterval + 1 }
    }

    private func makeEditor(clock: Clock) throws -> EditorViewModel {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.now = { clock.date }
        return editor
    }

    @Test func newEditorHasNothingToUndo() throws {
        let editor = try makeEditor(clock: Clock())
        #expect(!editor.canUndo && !editor.canRedo)
    }

    @Test func undoRemovesAddedElementAndRedoBringsItBack() throws {
        let editor = try makeEditor(clock: Clock())
        editor.addElement(of: .button)

        editor.undo()
        #expect(editor.screen.elements.isEmpty)
        #expect(editor.selectedElementID == nil)   // silinen eleman seçili kalmaz
        #expect(editor.canRedo)

        editor.redo()
        #expect(editor.screen.elements.count == 1)
    }

    @Test func undoRestoresDeletedElement() throws {
        let clock = Clock()
        let editor = try makeEditor(clock: clock)
        editor.addElement(of: .button)
        clock.pause()
        editor.deleteSelectedElement()

        editor.undo()

        #expect(editor.screen.elements.count == 1)
    }

    @Test func quickChangesAreOneStep() throws {
        let clock = Clock()
        let editor = try makeEditor(clock: clock)
        editor.addElement(of: .button)
        clock.pause()

        // Yazı yazmak gibi: harf harf, araya bekleme girmeden
        for text in ["G", "Gi", "Gir", "Giri", "Giriş"] {
            editor.updateSelectedProperties { $0.text = text }
            clock.date += 0.1
        }

        editor.undo()
        #expect(editor.selectedElement?.properties.text == "Button")   // tek adımda eski yazı
    }

    @Test func changesAfterAPauseAreSeparateSteps() throws {
        let clock = Clock()
        let editor = try makeEditor(clock: clock)
        editor.addElement(of: .button)
        clock.pause()
        editor.updateSelectedProperties { $0.text = "Bir" }
        clock.pause()
        editor.updateSelectedProperties { $0.text = "İki" }

        editor.undo()
        #expect(editor.selectedElement?.properties.text == "Bir")
    }

    @Test func newChangeClearsRedo() throws {
        let clock = Clock()
        let editor = try makeEditor(clock: clock)
        editor.addElement(of: .button)
        clock.pause()
        editor.updateSelectedProperties { $0.text = "Bir" }
        editor.undo()
        #expect(editor.canRedo)

        editor.updateSelectedProperties { $0.text = "Başka" }

        #expect(!editor.canRedo)
    }

    @Test func bringingToFrontIsNotAStep() throws {
        let clock = Clock()
        let editor = try makeEditor(clock: clock)
        editor.addElement(of: .image)
        let first = try #require(editor.selectedElementID)
        clock.pause()
        editor.addElement(of: .image)
        clock.pause()

        editor.select(first)   // öne getirir
        editor.undo()          // ikinci görselin eklenmesini geri alır

        #expect(editor.screen.elements.map(\.id) == [first])
    }

    @Test func undoHistoryIsLimited() throws {
        let clock = Clock()
        let editor = try makeEditor(clock: clock)
        editor.addElement(of: .button)
        for index in 0..<(EditorViewModel.undoLimit + 10) {
            clock.pause()
            editor.updateSelectedProperties { $0.text = "\(index)" }
        }

        #expect(editor.undoStack.count == EditorViewModel.undoLimit)
    }
}
