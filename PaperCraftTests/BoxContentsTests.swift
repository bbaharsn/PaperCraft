//
//  BoxContentsTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import Testing
@testable import PaperCraft

struct BoxContentsTests {

    /// Normalize frame'i 100 ile çarpan basit dönüşüm (test için 100×100 point'lik ekran).
    private let rect: (CanvasElement) -> CGRect = { e in
        CGRect(x: e.frame.x * 100, y: e.frame.y * 100, width: e.frame.width * 100, height: e.frame.height * 100)
    }

    private func element(_ type: ElementType, _ x: Double, _ y: Double, _ w: Double, _ h: Double,
                         rotation: Double? = nil) -> CanvasElement {
        var properties = ElementProperties()
        properties.rotation = rotation
        return CanvasElement(type: type, frame: NormalizedFrame(x: x, y: y, width: w, height: h),
                             properties: properties)
    }

    @Test func elementFullyInsideAndAboveBoxIsContent() {
        let box = element(.box, 0.1, 0.1, 0.5, 0.2)
        let symbol = element(.symbol, 0.15, 0.15, 0.1, 0.1)
        let group = BoxContents.group(startingFrom: [box.id], in: [box, symbol], rect: rect)
        #expect(group == [box.id, symbol.id])
    }

    @Test func elementBelowBoxInOrderIsNotContent() {
        let box = element(.box, 0.1, 0.1, 0.5, 0.2)
        let symbol = element(.symbol, 0.15, 0.15, 0.1, 0.1)
        let group = BoxContents.group(startingFrom: [box.id], in: [symbol, box], rect: rect)
        #expect(group == [box.id])
    }

    @Test func elementPartlyOutsideIsNotContent() {
        let box = element(.box, 0.1, 0.1, 0.5, 0.2)
        let text = element(.text, 0.4, 0.15, 0.22, 0.05)   // 2 pt taşıyor
        let group = BoxContents.group(startingFrom: [box.id], in: [box, text], rect: rect)
        #expect(group == [box.id])
    }

    @Test func nestedBoxBringsItsContents() {
        let outer = element(.box, 0, 0, 0.8, 0.5)
        let inner = element(.box, 0.1, 0.1, 0.4, 0.3)
        let text = element(.text, 0.15, 0.15, 0.1, 0.05)
        let group = BoxContents.group(startingFrom: [outer.id], in: [outer, inner, text], rect: rect)
        #expect(group == [outer.id, inner.id, text.id])
    }

    @Test func pinnedElementIsNeverContent() {
        let box = element(.box, 0, 0, 1, 0.5)
        let bar = element(.navigationBar, 0, 0, 1, 0.1)
        #expect(bar.isPinned)
        #expect(BoxContents.group(startingFrom: [box.id], in: [box, bar], rect: rect) == [box.id])
        #expect(BoxContents.group(startingFrom: [bar.id], in: [box, bar], rect: rect).isEmpty)
    }

    @Test func nonBoxSelectionStaysAsIs() {
        let symbol = element(.symbol, 0.1, 0.1, 0.5, 0.5)
        let text = element(.text, 0.2, 0.2, 0.1, 0.05)
        #expect(BoxContents.group(startingFrom: [symbol.id], in: [symbol, text], rect: rect) == [symbol.id])
    }

    @Test func rotatedChildUsesBoundingBox() {
        let box = element(.box, 0.1, 0.1, 0.2, 0.2)
        // Düzken tam sığan 20×20'lik sembol 45° dönünce köşeleri taşar.
        let symbol = element(.symbol, 0.1, 0.1, 0.2, 0.2, rotation: 45)
        #expect(BoxContents.group(startingFrom: [box.id], in: [box, symbol], rect: rect) == [box.id])
    }
}
