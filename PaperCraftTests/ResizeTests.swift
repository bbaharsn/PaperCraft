//
//  ResizeTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Testing
@testable import PaperCraft

@MainActor
struct ResizeTests {

    /// Boş ekrana tek bir buton (200 × 50, ortada) ekler ve seçili bırakır.
    private func makeEditorWithButton() throws -> EditorViewModel {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .button)
        return editor
    }

    private func rect(_ editor: EditorViewModel) throws -> CGRect {
        editor.pointRect(of: try #require(editor.selectedElement))
    }

    /// Normalize ↔ point dönüşümünde küçük yuvarlama farkları olabilir.
    private func isClose(_ a: CGFloat, _ b: CGFloat) -> Bool {
        abs(a - b) < 0.001
    }

    @Test func draggingBottomTrailingGrowsAndKeepsTopLeading() throws {
        let editor = try makeEditorWithButton()
        let before = try rect(editor)

        editor.resizeElement(try #require(editor.selectedElementID), from: .bottomTrailing,
                             by: CGSize(width: 40, height: 10))

        let after = try rect(editor)
        #expect(isClose(after.width, 240) && isClose(after.height, 60))
        #expect(isClose(after.minX, before.minX) && isClose(after.minY, before.minY))
    }

    @Test func draggingTopLeadingKeepsBottomTrailing() throws {
        let editor = try makeEditorWithButton()
        let before = try rect(editor)

        editor.resizeElement(try #require(editor.selectedElementID), from: .topLeading,
                             by: CGSize(width: 20, height: -10))

        let after = try rect(editor)
        #expect(isClose(after.width, 180) && isClose(after.height, 60))
        #expect(isClose(after.maxX, before.maxX) && isClose(after.maxY, before.maxY))
    }

    @Test func cannotShrinkBelowMinimumSize() throws {
        let editor = try makeEditorWithButton()

        editor.resizeElement(try #require(editor.selectedElementID), from: .bottomTrailing,
                             by: CGSize(width: -500, height: -500))

        let after = try rect(editor)
        #expect(isClose(after.width, 44) && isClose(after.height, 44))   // katalogdaki minSize
    }

    @Test func circleButtonStaysSquareWhileResizing() throws {
        let editor = try makeEditorWithButton()
        editor.setSelectedButtonShape(.circle)
        #expect(isClose(try rect(editor).width, 50))   // 200 × 50 → 50 × 50

        editor.resizeElement(try #require(editor.selectedElementID), from: .bottomTrailing,
                             by: CGSize(width: 30, height: 0))

        let after = try rect(editor)
        #expect(isClose(after.width, 80) && isClose(after.height, 80))
    }

    @Test func typedSizeIsClampedToMinimum() throws {
        let editor = try makeEditorWithButton()

        editor.setSelectedSize(width: 10, height: 70)

        let after = try rect(editor)
        #expect(isClose(after.width, 44) && isClose(after.height, 70))
    }

    @Test func typedHeightIsCappedAtOneScreen() throws {
        let editor = try makeEditorWithButton()

        editor.setSelectedSize(width: 72, height: 4434)   // 44 yazarken yanlışlıkla 4434

        #expect(isClose(try rect(editor).height, 852))
    }

    @Test func handlesLeaveSmallElementsFreeToDrag() {
        // Kısa kenarda dokunma alanı tamamen elemanın dışında
        #expect(SelectionOverlay.outwardShift(side: 24, hitSize: 36, freeSize: 44) == 18)
        // Orta boyda alan kısmen içeri girer
        #expect(SelectionOverlay.outwardShift(side: 54, hitSize: 36, freeSize: 44) == 13)
        // Uzun kenarda alan köşeye ortalanır
        #expect(SelectionOverlay.outwardShift(side: 200, hitSize: 36, freeSize: 44) == 0)
    }
}
