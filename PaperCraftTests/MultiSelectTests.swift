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

    @Test func ungroupRemovesOnlyBoxAndSelectsContents() throws {
        let (editor, box, symbol, button) = try boxScene()
        let symbolFrame = try #require(editor.screen.elements.first { $0.id == symbol }?.frame)
        editor.select(box)
        #expect(editor.canUngroupSelected)

        editor.ungroupSelectedBox()

        let ids = editor.screen.elements.map(\.id)
        #expect(!ids.contains(box) && ids.contains(symbol) && ids.contains(button))
        #expect(editor.isMultiSelecting)
        #expect(editor.multiSelection == [symbol])
        #expect(editor.selectedElementID == nil)
        #expect(editor.screen.elements.first { $0.id == symbol }?.frame == symbolFrame)
    }

    @Test func ungroupIsOneUndoStep() throws {
        let (editor, box, _, _) = try boxScene()
        editor.select(box)
        let before = editor.screen
        editor.ungroupSelectedBox()
        #expect(editor.undoStack.count == 1)
        editor.undo()
        #expect(editor.screen == before)
    }

    /// Geri al, çözmeden önceki hali getirir: kutu tek başına seçili, toplu mod kapalı.
    @Test func undoingUngroupSelectsTheBoxAgain() throws {
        let (editor, box, _, _) = try boxScene()
        editor.select(box)
        editor.ungroupSelectedBox()

        editor.undo()

        #expect(!editor.isMultiSelecting)
        #expect(editor.multiSelection.isEmpty)
        #expect(editor.selectedElementID == box)
    }

    /// Çözdükten sonra başka bir değişiklik yapıldıysa geri al o değişikliği geri alır, seçime dokunmaz.
    @Test func undoAfterAnotherChangeKeepsMultiSelection() throws {
        let (editor, box, symbol, _) = try boxScene()
        editor.select(box)
        editor.ungroupSelectedBox()
        editor.moveGroup([symbol], dx: 0.05, dy: 0)

        editor.undo()

        #expect(editor.isMultiSelecting)
        #expect(editor.multiSelection == [symbol])
    }

    /// Toplu seçim köşeden çekilince hepsi aynı oranla büyür; bütün sürükleme tek geri al adımıdır.
    @Test func resizingMultiSelectionScalesAllAndIsOneUndoStep() throws {
        let a = element(.button, x: 0.1, y: 0.4, width: 0.2, height: 0.06)
        let b = element(.button, x: 0.4, y: 0.5, width: 0.2, height: 0.06)
        let editor = try editor([a, b])
        let before = editor.screen
        editor.toggleMultiSelectMode()
        editor.toggleInMultiSelection(a.id)
        editor.toggleInMultiSelection(b.id)
        let groupWidth = (0.6 - 0.1) * editor.canvasSize.width

        editor.beginMultiSelectionResize()
        editor.resizeMultiSelection(from: .bottomTrailing, by: CGSize(width: groupWidth * 0.1, height: 0))
        editor.resizeMultiSelection(from: .bottomTrailing, by: CGSize(width: groupWidth * 0.2, height: 0))
        editor.endMultiSelectionResize()

        let frames = editor.screen.elements.map(\.frame)
        #expect(abs(frames[0].x - 0.1) < 1e-9)                       // karşı köşe yerinde
        #expect(abs(frames[0].width - 0.24) < 1e-9)                  // 1,2 kat (son çeviri esas)
        #expect(abs(frames[1].x - (0.1 + 0.3 * 1.2)) < 1e-9)          // aradaki boşluk da büyür
        #expect(abs(frames[1].height - 0.072) < 1e-9)                // oran korunur
        #expect(editor.undoStack.count == 1)
        editor.undo()
        #expect(editor.screen == before)
    }

    /// Toplu büyütmede yazılar da aynı oranda büyür.
    @Test func resizingMultiSelectionScalesContent() throws {
        let a = element(.button, x: 0.1, y: 0.4, width: 0.2, height: 0.06)
        let b = element(.text, x: 0.4, y: 0.5, width: 0.2, height: 0.06)
        let editor = try editor([a, b])
        editor.toggleMultiSelectMode()
        editor.toggleInMultiSelection(a.id)
        editor.toggleInMultiSelection(b.id)
        let groupWidth = (0.6 - 0.1) * editor.canvasSize.width

        editor.beginMultiSelectionResize()
        editor.resizeMultiSelection(from: .bottomTrailing, by: CGSize(width: groupWidth * 0.1, height: 0))
        editor.resizeMultiSelection(from: .bottomTrailing, by: CGSize(width: groupWidth * 0.5, height: 0))
        editor.endMultiSelectionResize()

        for element in editor.screen.elements {
            #expect(abs((element.properties.contentScale ?? 1) - 1.5) < 1e-9)
        }
    }

    @Test func resizingMultiSelectionScalesBoxContents() throws {
        let (editor, box, symbol, _) = try boxScene()
        editor.toggleMultiSelectMode()
        editor.toggleInMultiSelection(box)
        let groupWidth = 0.6 * editor.canvasSize.width

        editor.beginMultiSelectionResize()
        editor.resizeMultiSelection(from: .bottomTrailing, by: CGSize(width: groupWidth * 0.25, height: 0))
        editor.endMultiSelectionResize()

        let symbolFrame = try #require(editor.screen.elements.first { $0.id == symbol }?.frame)
        #expect(abs(symbolFrame.width - 0.125) < 1e-9)
        #expect(abs(symbolFrame.x - (0.1 + 0.05 * 1.25)) < 1e-9)
    }

    @Test func cannotUngroupEmptyBoxOrNonBox() throws {
        let emptyBox = element(.box, x: 0.1, y: 0.6, width: 0.3, height: 0.1)
        let (editor, _, _, button) = try boxScene()
        editor.screen.elements.append(emptyBox)

        editor.select(emptyBox.id)
        #expect(!editor.canUngroupSelected)
        let before = editor.screen
        editor.ungroupSelectedBox()
        #expect(editor.screen == before)

        editor.select(button)
        #expect(!editor.canUngroupSelected)
    }

    @Test func ungroupNestedKeepsInnerBox() throws {
        let outer = element(.box, x: 0.1, y: 0.1, width: 0.8, height: 0.4)
        let inner = element(.box, x: 0.15, y: 0.15, width: 0.4, height: 0.2)
        let symbol = element(.symbol, x: 0.2, y: 0.2, width: 0.1, height: 0.05)
        let editor = try editor([outer, inner, symbol])
        editor.select(outer.id)

        editor.ungroupSelectedBox()

        #expect(editor.screen.elements.map(\.id) == [inner.id, symbol.id])
        #expect(editor.multiSelection == [inner.id, symbol.id])
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
