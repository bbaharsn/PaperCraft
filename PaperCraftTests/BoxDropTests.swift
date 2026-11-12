//
//  BoxDropTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import Testing
@testable import PaperCraft

/// Kutu sayfada duran elemanların üstüne bırakılınca onları örtmez, içine alır.
@MainActor
struct BoxDropTests {

    private let rect: (CanvasElement) -> CGRect = { e in
        CGRect(x: e.frame.x * 100, y: e.frame.y * 100, width: e.frame.width * 100, height: e.frame.height * 100)
    }

    private func element(_ type: ElementType, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CanvasElement {
        CanvasElement(type: type, frame: NormalizedFrame(x: x, y: y, width: w, height: h),
                      properties: ElementProperties())
    }

    @Test func coveredElementsMoveRightAboveTheBox() {
        let text = element(.text, 0.2, 0.2, 0.2, 0.05)
        let symbol = element(.symbol, 0.5, 0.2, 0.1, 0.05)
        let outside = element(.button, 0.2, 0.8, 0.4, 0.06)
        let box = element(.box, 0.1, 0.1, 0.6, 0.3)
        let result = BoxContents.liftingCovered(by: [box.id], in: [text, outside, symbol, box], rect: rect)
        // Dışarıdaki buton yerinde kalır; içeridekiler sıralarını koruyarak kutunun üstüne geçer
        #expect(result.map(\.id) == [outside.id, box.id, text.id, symbol.id])
        #expect(BoxContents.group(startingFrom: [box.id], in: result, rect: rect) == [box.id, text.id, symbol.id])
    }

    @Test func partlyCoveredElementStaysBelow() {
        let wide = element(.button, 0.05, 0.2, 0.9, 0.06)   // kutudan taşıyor
        let box = element(.box, 0.1, 0.1, 0.6, 0.3)
        let result = BoxContents.liftingCovered(by: [box.id], in: [wide, box], rect: rect)
        #expect(result.map(\.id) == [wide.id, box.id])
    }

    @Test func bigCardBehindIsNotLifted() {
        // Küçük kutu büyük bir kartın üstüne bırakılınca kart öne gelmez
        let card = element(.box, 0, 0, 1, 0.6)
        let box = element(.box, 0.2, 0.2, 0.3, 0.2)
        let result = BoxContents.liftingCovered(by: [box.id], in: [card, box], rect: rect)
        #expect(result.map(\.id) == [card.id, box.id])
    }

    @Test func innerBoxComesUpWithItsContents() {
        let small = element(.box, 0.2, 0.2, 0.3, 0.1)
        let icon = element(.symbol, 0.25, 0.22, 0.05, 0.05)
        let big = element(.box, 0.1, 0.1, 0.6, 0.4)
        let result = BoxContents.liftingCovered(by: [big.id], in: [small, icon, big], rect: rect)
        #expect(result.map(\.id) == [big.id, small.id, icon.id])
    }

    @Test func droppingABoxIsOneUndoStep() throws {
        let symbol = element(.symbol, 0.5, 0.5, 0.1, 0.05)
        let box = element(.box, 0.1, 0.1, 0.4, 0.2)
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(),
                                     screen: PrototypeScreen(name: "Test", elements: [symbol, box]))
        // Kutuyu sembolün üstüne taşı
        editor.moveGroup([box.id], dx: 0.35, dy: 0.35)
        #expect(editor.screen.elements.map(\.id) == [box.id, symbol.id])
        #expect(editor.movingGroup(for: [box.id]) == [box.id, symbol.id])

        editor.undo()
        #expect(editor.screen.elements.map(\.id) == [symbol.id, box.id])
        #expect(abs(editor.screen.elements[1].frame.x - 0.1) < 0.001)
    }
}

extension BoxDropTests {
    @Test func boxAddedFromCatalogTakesWhatIsUnderIt() throws {
        // Kutu katalogdan sayfanın ortasına eklenir; ortadaki küçük sembol örtülmez, içine alınır
        let catalog = try ComponentCatalog.load()
        let symbol = element(.symbol, 0.48, 0.48, 0.04, 0.02)
        let editor = EditorViewModel(catalog: catalog, screen: PrototypeScreen(name: "Test", elements: [symbol]))
        editor.addElement(of: .box, centeredAt: CGPoint(x: 0.5, y: 0.5))
        let box = try #require(editor.screen.elements.first { $0.type == .box })
        #expect(editor.screen.elements.map(\.id) == [box.id, symbol.id])
        editor.undo()
        #expect(editor.screen.elements.map(\.id) == [symbol.id])
    }
}
