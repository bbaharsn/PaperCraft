//
//  EditorViewModelTests.swift
//  PaperCraftTests
//

import Testing
@testable import PaperCraft

@MainActor
struct EditorViewModelTests {

    /// Her test boş bir ekranla başlar.
    private func makeEditor() throws -> EditorViewModel {
        EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
    }

    @Test func addingElementAppendsAndSelectsIt() throws {
        let editor = try makeEditor()

        editor.addElement(of: .button)

        #expect(editor.screen.elements.count == 1)
        #expect(editor.screen.elements.first?.type == .button)
        #expect(editor.selectedElementID == editor.screen.elements.first?.id)
    }

    @Test func addingUnknownTypeDoesNothing() throws {
        let editor = try makeEditor()

        editor.addElement(of: .unknown)

        #expect(editor.screen.elements.isEmpty)
        #expect(editor.selectedElementID == nil)
    }

    @Test func deletingRemovesSelectedElementAndClearsSelection() throws {
        let editor = try makeEditor()
        editor.addElement(of: .text)
        editor.addElement(of: .button)          // buton seçili

        editor.deleteSelectedElement()

        #expect(editor.screen.elements.map(\.type) == [.text])   // sadece buton gitti
        #expect(editor.selectedElementID == nil)
    }

    @Test func deletingWithoutSelectionDoesNothing() throws {
        let editor = try makeEditor()
        editor.addElement(of: .text)
        editor.select(nil)

        editor.deleteSelectedElement()

        #expect(editor.screen.elements.count == 1)
    }

    @Test func movingElementStaysInsideScreen() throws {
        let editor = try makeEditor()
        editor.addElement(of: .button)
        let id = try #require(editor.screen.elements.first?.id)

        editor.moveElement(id, dx: 5, dy: -5)   // çok uzağa sürükle

        let frame = editor.screen.elements[0].frame
        #expect(frame.x + frame.width <= 1)     // sağ kenardan taşmadı
        #expect(frame.y >= 0)                   // üst kenardan taşmadı
    }
}
