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

    // MARK: - İçerik çerçeveyle büyür

    private func contentScale(_ editor: EditorViewModel) throws -> Double {
        try #require(editor.selectedElement).properties.contentScale ?? 1
    }

    // MARK: - Metin kutusu yazıya oturur

    private func makeEditorWithText() throws -> EditorViewModel {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .text)
        return editor
    }

    /// Yeni metnin kutusu yazının kendisi kadar (katalogdaki 200 pt değil).
    @Test func newTextBoxFitsItsText() throws {
        let editor = try makeEditorWithText()
        let element = try #require(editor.selectedElement)
        let expected = TextMeasure.size(of: element.properties, maxWidth: editor.canvasSize.width)

        let box = try rect(editor)
        #expect(isClose(box.width, expected.width) && isClose(box.height, expected.height))
        #expect(box.width < 100)
    }

    /// Yazı uzayınca kutu da uzar; renk değişince kutu yerinde kalır.
    @Test func textBoxFollowsTextButNotColor() throws {
        let editor = try makeEditorWithText()
        let short = try rect(editor)

        editor.updateSelectedProperties { $0.text = "Çok daha uzun bir yazı" }
        let long = try rect(editor)
        #expect(long.width > short.width + 50)
        #expect(isClose(long.midX, short.midX))   // ortaya hizalı: ortası yerinde

        editor.updateSelectedProperties { $0.contentColor = "#FF0000" }
        #expect(try rect(editor) == long)
    }

    /// Köşeden çoğunlukla aşağı çekmek de kutuyu ve yazıyı birlikte, oranı korunarak büyütür.
    @Test func textResizesProportionallyAndBoxKeepsFitting() throws {
        let editor = try makeEditorWithText()
        let id = try #require(editor.selectedElementID)
        let before = try rect(editor)

        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: 1, height: before.height * 0.25))
        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: 0, height: before.height * 0.25))
        editor.endElementResize()

        let element = try #require(editor.selectedElement)
        #expect(try isClose(contentScale(editor), 1.5))
        let expected = TextMeasure.size(of: element.properties, maxWidth: editor.canvasSize.width)
        let after = try rect(editor)
        #expect(isClose(after.width, expected.width) && isClose(after.height, expected.height))
        #expect(isClose(after.minX, before.minX) && isClose(after.minY, before.minY))
    }

    /// Metin sayfanın sağ kenarına gelince büyüme durur.
    @Test func proportionalTextStopsAtPageEdge() throws {
        let editor = try makeEditorWithText()
        let id = try #require(editor.selectedElementID)

        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: 0, height: 2000))
        editor.endElementResize()

        #expect(try rect(editor).maxX <= editor.canvasSize.width + 1)
    }

    /// Eski projelerdeki geniş kutu (200 pt'de kısa bir sayı) ilk çekişte yazıya oturur;
    /// yazı yerinden oynamaz.
    @Test func wideLegacyTextBoxSnapsToTextOnResize() throws {
        var properties = ElementProperties(text: "7", textStyle: .body)
        properties.textAlignment = .leading
        let element = CanvasElement(type: .text, frame: NormalizedFrame(x: 0.2, y: 0.2, width: 200 / 393, height: 30 / 852),
                                    properties: properties)
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(),
                                     screen: PrototypeScreen(name: "Test", elements: [element]))
        editor.select(element.id)
        let before = try rect(editor)

        editor.resizeElement(element.id, from: .bottomTrailing, by: CGSize(width: 0, height: 1))
        editor.endElementResize()

        let after = try rect(editor)
        #expect(after.width < 40)
        #expect(isClose(after.minX, before.minX))
    }

    /// Çekiş iptal olup bitiş haberi gelmese de (telefonda ikinci parmak) eleman başka yoldan değişince
    /// sonraki çekiş eski hareketi taşımaz; yeni yerinden başlar.
    @Test func staleResizeDoesNotLeakIntoNextDrag() throws {
        let editor = try makeEditorWithButton()   // 200 × 50
        let id = try #require(editor.selectedElementID)

        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: 40, height: 0))   // bitiş yok
        editor.moveElement(id, dx: 0, dy: 0.1)
        let moved = try rect(editor)

        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: 10, height: 0))
        let after = try rect(editor)
        #expect(isClose(after.minX, moved.minX) && isClose(after.minY, moved.minY))
        #expect(isClose(after.width, moved.width + 10))
    }

    /// Yazı hep kutuya sığsın diye küçük oran esas alınır: sadece yana ya da sadece aşağı çekmek değiştirmez.
    @Test func contentFollowsTheSmallerRatio() throws {
        let editor = try makeEditorWithButton()   // 200 × 50
        let id = try #require(editor.selectedElementID)

        // Buton ortada (x = 96,5): sağda 96,5 pt, solda 96,5 pt yer var.
        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: 40, height: 0))   // 240 × 50
        editor.endElementResize()
        #expect(try isClose(contentScale(editor), 1))

        editor.resizeElement(id, from: .topLeading, by: CGSize(width: 0, height: -50))   // 240 × 100
        #expect(try isClose(contentScale(editor), 1))
        editor.resizeElement(id, from: .topLeading, by: CGSize(width: -96, height: 0))   // 336 × 100
        editor.endElementResize()
        #expect(try isClose(contentScale(editor), 1.4))   // genişlik 240 → 336
    }

    /// Bir yana bir öbür yana kayan sürükleme de toplam değişime göre ölçeklenir ve tek geri al adımıdır.
    @Test func zigzagDragScalesByTotalAndIsOneUndoStep() throws {
        let editor = try makeEditorWithButton()   // 200 × 50
        let id = try #require(editor.selectedElementID)
        let before = editor.screen
        let undoCount = editor.undoStack.count

        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: 20, height: 0))
        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: 0, height: 5))
        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: 20, height: 0))
        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: 0, height: 5))
        editor.endElementResize()

        #expect(try isClose(contentScale(editor), 1.2))   // 240 × 60
        #expect(editor.undoStack.count == undoCount + 1)
        editor.undo()
        #expect(editor.screen == before)
    }

    /// Özellikler sayfasından yazılan ölçü sadece kutuyu değiştirir.
    @Test func typedSizeKeepsContentScale() throws {
        let editor = try makeEditorWithButton()

        editor.setSelectedSize(width: 290, height: 100)

        #expect(try #require(editor.selectedElement).properties.contentScale == nil)
    }

    /// Görsel, sembol ve kutu zaten çerçeveyi doldurur; ölçek değeri onlara yazılmaz.
    @Test func fillingElementsDoNotGetContentScale() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .box)

        editor.resizeElement(try #require(editor.selectedElementID), from: .bottomTrailing,
                             by: CGSize(width: 50, height: 50))

        #expect(try #require(editor.selectedElement).properties.contentScale == nil)
    }

    @Test func scalingTypes() {
        let scaling: [ElementType] = [.text, .button, .textField, .switch, .slider]
        let filling: [ElementType] = [.image, .symbol, .box, .navigationBar, .tabBar, .unknown]
        #expect(scaling.filter { !$0.scalesContentWithFrame }.isEmpty)
        #expect(filling.filter { $0.scalesContentWithFrame }.isEmpty)
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
