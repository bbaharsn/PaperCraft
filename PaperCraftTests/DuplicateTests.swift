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
