//
//  PreviewTests.swift
//  PaperCraftTests
//

import Foundation
import Testing
@testable import PaperCraft

@MainActor
struct PreviewTests {

    private func makeEditor() throws -> EditorViewModel {
        EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
    }

    @Test func updatingPropertiesChangesOnlyThatElement() throws {
        let editor = try makeEditor()
        editor.addElement(of: .switch)
        editor.addElement(of: .switch)
        var screen = editor.screen
        let first = screen.elements[0]
        let second = screen.elements[1]

        screen.updateProperties(of: second.id) { $0.isOn = !(second.properties.isOn ?? false) }

        #expect(screen.elements[0].properties == first.properties)
        #expect(screen.elements[1].properties.isOn == !(second.properties.isOn ?? false))
    }

    @Test func updatingUnknownElementChangesNothing() throws {
        let editor = try makeEditor()
        editor.addElement(of: .slider)
        var screen = editor.screen

        screen.updateProperties(of: UUID()) { $0.value = 99 }

        #expect(screen == editor.screen)
    }

    @Test func previewChangesDoNotTouchTheDesign() throws {
        let editor = try makeEditor()
        editor.addElement(of: .textField)
        let id = try #require(editor.selectedElementID)

        // Önizleme ekranın bir kopyasıyla açılır; kullanıcı metin kutusuna yazı yazar
        var preview = editor.screen
        preview.updateProperties(of: id) { $0.text = "deneme@ornek.com" }

        #expect(preview.elements[0].properties.text == "deneme@ornek.com")
        #expect(editor.screen.elements[0].properties.text == nil)
    }

    /// iPhone 13 ve iPhone SE: farklı boy, farklı durum çubuğu.
    @Test(arguments: [(CGSize(width: 390, height: 844), CGFloat(47)),
                      (CGSize(width: 375, height: 667), CGFloat(20))])
    func barsSitOnTheSafeEdges(screen: CGSize, topInset: CGFloat) {
        let layout = PreviewLayout(stageSize: screen, topInset: topInset)
        let reference = CanvasView.referenceSize

        let navigationHeight: CGFloat = 44
        let navigationBar = NormalizedFrame(x: 0, y: 0, width: 1, height: navigationHeight / reference.height)
        let navigationTop = layout.center(of: navigationBar).y - navigationHeight / 2
        #expect(abs(navigationTop) < 0.001)

        let tabHeight: CGFloat = 83
        let tabBar = NormalizedFrame(x: 0, y: 1 - tabHeight / reference.height,
                                     width: 1, height: tabHeight / reference.height)
        let tabBottom = (layout.center(of: tabBar).y + tabHeight / 2) * layout.scale + topInset
        #expect(abs(tabBottom - screen.height) < 0.001)
    }

    @Test func closedCardMatchesTheCanvasExactly() {
        // Durum çubuğu payı yokken tasarım canvas'taki konumlarıyla birebir aynı
        let reference = CanvasView.referenceSize
        let layout = PreviewLayout(stageSize: reference, topInset: 0)
        let frame = NormalizedFrame(x: 0.1, y: 0.5, width: 0.5, height: 0.1)

        #expect(layout.scale == 1)
        #expect(abs(layout.center(of: frame).y - 0.55 * reference.height) < 0.001)
    }

    @Test func wideScreensKeepPhoneProportions() {
        #expect(PreviewLayout.stageWidth(for: CGSize(width: 390, height: 844)) == 390)
        #expect(PreviewLayout.stageWidth(for: CGSize(width: 1000, height: 1000)) == 600)
    }

    @Test func keyboardLiftsOnlyWhatItCovers() {
        let layout = PreviewLayout(stageSize: CGSize(width: 390, height: 844), topInset: 47)
        let lowField = NormalizedFrame(x: 0.1, y: 0.8, width: 0.8, height: 0.05)
        let highField = NormalizedFrame(x: 0.1, y: 0.1, width: 0.8, height: 0.05)

        #expect(layout.keyboardLift(for: lowField, keyboardHeight: 0) == 0)
        #expect(layout.keyboardLift(for: highField, keyboardHeight: 336) == 0)

        let lift = layout.keyboardLift(for: lowField, keyboardHeight: 336)
        let reference = CanvasView.referenceSize
        let fieldBottom = 47 + layout.center(of: lowField).y * layout.scale
            + lowField.height * reference.height * layout.scale / 2
        #expect(abs(fieldBottom - lift - (844 - 336 - 16)) < 0.001)
    }

    @Test func tallElementNeverLiftsPastTheStatusBar() {
        let layout = PreviewLayout(stageSize: CGSize(width: 390, height: 844), topInset: 47)
        let tall = NormalizedFrame(x: 0, y: 0.1, width: 1, height: 0.8)

        let lift = layout.keyboardLift(for: tall, keyboardHeight: 336)
        let top = layout.center(of: tall).y * layout.scale
            - tall.height * CanvasView.referenceSize.height * layout.scale / 2
        #expect(top - lift >= 16 - 0.001)
    }
}
