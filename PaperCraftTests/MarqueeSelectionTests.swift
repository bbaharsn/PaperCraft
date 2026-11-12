//
//  MarqueeSelectionTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import Testing
@testable import PaperCraft

@MainActor
struct MarqueeSelectionTests {

    private func element(_ type: ElementType, x: Double, y: Double, width: Double, height: Double) -> CanvasElement {
        CanvasElement(type: type, frame: NormalizedFrame(x: x, y: y, width: width, height: height),
                      properties: ElementProperties())
    }

    private func editor(_ elements: [CanvasElement]) throws -> EditorViewModel {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(),
                                     screen: PrototypeScreen(name: "Test", elements: elements))
        editor.toggleMultiSelectMode()
        return editor
    }

    /// Normalize çerçeve → sayfa point'i (393×852).
    private func points(x: Double, y: Double, width: Double, height: Double) -> CGRect {
        CGRect(x: x * 393, y: y * 852, width: width * 393, height: height * 852)
    }

    @Test func selectsElementsTheMarqueeTouches() throws {
        let inside = element(.symbol, x: 0.2, y: 0.2, width: 0.1, height: 0.05)
        let partly = element(.button, x: 0.25, y: 0.3, width: 0.6, height: 0.06)
        let outside = element(.text, x: 0.2, y: 0.8, width: 0.3, height: 0.04)
        let editor = try editor([inside, partly, outside])

        editor.selectInMarquee(points(x: 0.1, y: 0.1, width: 0.4, height: 0.3), adding: [])
        #expect(editor.multiSelection == [inside.id, partly.id])
    }

    @Test func boxAroundTheMarqueeIsNotSelected() throws {
        // Arka plandaki büyük kutunun içine çizilen çerçeve, kutuyu değil içindekini seçer
        let card = element(.box, x: 0.05, y: 0.1, width: 0.9, height: 0.5)
        let symbol = element(.symbol, x: 0.2, y: 0.2, width: 0.1, height: 0.05)
        let editor = try editor([card, symbol])

        editor.selectInMarquee(points(x: 0.15, y: 0.15, width: 0.2, height: 0.15), adding: [])
        #expect(editor.multiSelection == [symbol.id])
    }

    @Test func keepsEarlierSelectionAndDropsWhenMarqueeShrinks() throws {
        let tapped = element(.text, x: 0.2, y: 0.8, width: 0.3, height: 0.04)
        let first = element(.symbol, x: 0.1, y: 0.1, width: 0.1, height: 0.05)
        let second = element(.symbol, x: 0.5, y: 0.1, width: 0.1, height: 0.05)
        let editor = try editor([tapped, first, second])
        editor.toggleInMultiSelection(tapped.id)
        let base = editor.multiSelection

        editor.selectInMarquee(points(x: 0.05, y: 0.05, width: 0.6, height: 0.15), adding: base)
        #expect(editor.multiSelection == [tapped.id, first.id, second.id])

        // Çerçeve geri çekilince ikinci sembol düşer, önceden seçilen kalır
        editor.selectInMarquee(points(x: 0.05, y: 0.05, width: 0.3, height: 0.15), adding: base)
        #expect(editor.multiSelection == [tapped.id, first.id])
    }

    @Test func ignoresPinnedBars() throws {
        let bar = element(.navigationBar, x: 0, y: 0.05, width: 1, height: 0.06)   // varsayılan: Sabit
        #expect(bar.isPinned)
        let editor = try editor([bar])
        editor.selectInMarquee(points(x: 0, y: 0, width: 1, height: 0.5), adding: [])
        #expect(editor.multiSelection.isEmpty)
    }

    @Test func worksWhenDrawnUpwardsAndLeft() {
        let symbol = element(.symbol, x: 0.2, y: 0.2, width: 0.1, height: 0.05)
        // Genişliği ve yüksekliği eksi olan çerçeve (sağ alttan sol üste çizilmiş)
        let marquee = CGRect(x: 0.5 * 393, y: 0.4 * 852, width: -0.4 * 393, height: -0.3 * 852)
        let ids = MarqueeSelection.ids(in: marquee, elements: [symbol]) {
            CGRect(x: $0.frame.x * 393, y: $0.frame.y * 852,
                   width: $0.frame.width * 393, height: $0.frame.height * 852)
        }
        #expect(ids == [symbol.id])
    }

    @Test func usesRotatedBounds() {
        var symbol = element(.symbol, x: 0.2, y: 0.2, width: 0.3, height: 0.02)
        symbol.properties.rotation = 90
        let rect: (CanvasElement) -> CGRect = {
            CGRect(x: $0.frame.x * 393, y: $0.frame.y * 852,
                   width: $0.frame.width * 393, height: $0.frame.height * 852)
        }
        // Döndürülmemiş halinin sol ucu; dikey duran eleman buraya uzanmaz
        let flat = rect(symbol)
        let leftEnd = CGRect(x: flat.minX + 2, y: flat.midY - 2, width: 20, height: 4)
        #expect(MarqueeSelection.ids(in: leftEnd, elements: [symbol], rect: rect).isEmpty)
        // Dönmüş halinin üst ucunu geçen çerçeve
        let rotated = SnapGuides.boundingBox(flat, degrees: 90)
        let topEnd = CGRect(x: rotated.midX - 2, y: rotated.minY - 10, width: 4, height: 20)
        #expect(MarqueeSelection.ids(in: topEnd, elements: [symbol], rect: rect) == [symbol.id])
    }
}
