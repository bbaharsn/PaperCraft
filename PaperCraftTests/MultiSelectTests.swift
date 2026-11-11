//
//  MultiSelectTests.swift
//  PaperCraftTests
//

import Foundation
import Testing
@testable import PaperCraft

@MainActor
struct MultiSelectTests {

    private func element(_ type: ElementType, x: Double, y: Double, width: Double, height: Double) -> CanvasElement {
        CanvasElement(type: type, frame: NormalizedFrame(x: x, y: y, width: width, height: height),
                      properties: ElementProperties())
    }

    private func editor(_ elements: [CanvasElement]) throws -> EditorViewModel {
        EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test", elements: elements))
    }

    /// Kutu, içinde bir sembol ve kutunun dışında bir buton.
    private func boxScene() throws -> (EditorViewModel, box: UUID, symbol: UUID, button: UUID) {
        let box = element(.box, x: 0.1, y: 0.1, width: 0.6, height: 0.2)
        let symbol = element(.symbol, x: 0.15, y: 0.15, width: 0.1, height: 0.05)
        let button = element(.button, x: 0.1, y: 0.5, width: 0.4, height: 0.06)
        return (try editor([box, symbol, button]), box.id, symbol.id, button.id)
    }

    @Test func toggleModeClearsSelection() throws {
        let (editor, box, _, _) = try boxScene()
        editor.select(box)
        editor.toggleMultiSelectMode()
        #expect(editor.isMultiSelecting && editor.selectedElementID == nil)
        editor.toggleInMultiSelection(box)
        editor.toggleMultiSelectMode()
        #expect(!editor.isMultiSelecting && editor.multiSelection.isEmpty)
    }

    @Test func tapTogglesMembershipWithoutReordering() throws {
        let (editor, box, _, _) = try boxScene()
        let order = editor.screen.elements.map(\.id)
        editor.toggleMultiSelectMode()
        editor.toggleInMultiSelection(box)
        #expect(editor.multiSelection == [box])
        #expect(editor.screen.elements.map(\.id) == order)
        editor.toggleInMultiSelection(box)
        #expect(editor.multiSelection.isEmpty)
    }

    @Test func pinnedElementCannotJoinMultiSelection() throws {
        let bar = element(.navigationBar, x: 0, y: 0, width: 1, height: 0.1)
        let editor = try editor([bar])
        editor.toggleMultiSelectMode()
        editor.toggleInMultiSelection(bar.id)
        #expect(editor.multiSelection.isEmpty)
    }

    @Test func selectingBoxKeepsContentsOnTop() throws {
        let (editor, box, symbol, button) = try boxScene()
        editor.select(box)
        #expect(editor.screen.elements.map(\.id) == [button, box, symbol])
        #expect(!editor.canUndo)   // öne getirme geri al adımı değil
    }

    @Test func movingGroupIsOneUndoStep() throws {
        let (editor, box, symbol, _) = try boxScene()
        let before = editor.screen
        editor.moveGroup([box, symbol], dx: 0.1, dy: 0.1)
        #expect(editor.undoStack.count == 1)
        editor.undo()
        #expect(editor.screen == before)
    }

    @Test func moveGroupKeepsSpacingAtEdge() throws {
        let a = element(.button, x: 0.1, y: 0.2, width: 0.1, height: 0.05)
        let b = element(.button, x: 0.5, y: 0.2, width: 0.1, height: 0.05)
        let editor = try editor([a, b])
        editor.moveGroup([a.id, b.id], dx: -0.3, dy: 0)
        let xs = editor.screen.elements.map(\.frame.x)
        #expect(abs(xs[0]) < 1e-9 && abs(xs[1] - 0.4) < 1e-9)
    }

    @Test func deletingBoxDeletesContents() throws {
        let (editor, box, _, button) = try boxScene()
        editor.select(box)
        editor.deleteSelectedElement()
        #expect(editor.screen.elements.map(\.id) == [button])
    }

    @Test func deletingBoxIsOneUndoStepAndRestoresOrder() throws {
        let (editor, box, _, _) = try boxScene()
        editor.select(box)
        let before = editor.screen
        editor.deleteSelectedElement()
        #expect(editor.undoStack.count == 1)
        editor.undo()
        #expect(editor.screen == before)
    }

    @Test func deleteMultiSelectionDeletesAllAndBoxContents() throws {
        let (editor, box, _, button) = try boxScene()
        editor.toggleMultiSelectMode()
        editor.toggleInMultiSelection(box)
        editor.toggleInMultiSelection(button)
        editor.deleteMultiSelection()
        #expect(editor.screen.elements.isEmpty)
        #expect(editor.multiSelection.isEmpty)
        #expect(editor.undoStack.count == 1)
    }

    @Test func undoPrunesMultiSelection() throws {
        let editor = try editor([])
        editor.addElement(of: .button)
        let id = try #require(editor.selectedElementID)
        editor.toggleMultiSelectMode()
        editor.toggleInMultiSelection(id)
        editor.undo()
        #expect(editor.multiSelection.isEmpty)
    }
}
