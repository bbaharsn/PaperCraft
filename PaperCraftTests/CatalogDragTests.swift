//
//  CatalogDragTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Testing
@testable import PaperCraft

@MainActor
struct CatalogDragTests {

    private func editor() throws -> EditorViewModel {
        EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
    }

    private func isClose(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 0.0001 }

    /// Alan kartla aynı oranda: kart alanı tam doldurur, ölçek 1/2.
    private let area = CGRect(x: 100, y: 200, width: 196.5, height: 426)

    // MARK: - Ekran noktası → sayfa noktası

    @Test func centerOfCardIsCenterOfPage() throws {
        let mapping = CanvasMapping(area: area, viewport: CanvasViewport())
        let point = try #require(mapping.pagePoint(forGlobal: CGPoint(x: area.midX, y: area.midY)))
        #expect(isClose(point.x, 0.5))
        #expect(isClose(point.y, 0.5))
    }

    @Test func scrolledPageAddsScroll() throws {
        let mapping = CanvasMapping(area: area, viewport: CanvasViewport(scroll: 852))
        let point = try #require(mapping.pagePoint(forGlobal: CGPoint(x: area.minX, y: area.minY)))
        #expect(isClose(point.x, 0))
        #expect(isClose(point.y, 1))
    }

    @Test func zoomedAndPannedCard() throws {
        // 2× büyütülmüş, 50 pt sağa kaydırılmış kart: alanın ortası kartın ortasının 25 pt (tuvalde) solu
        let viewport = CanvasViewport(zoom: 2, pan: CGSize(width: 50, height: 0))
        let mapping = CanvasMapping(area: area, viewport: viewport)
        #expect(isClose(mapping.scale, 1))
        let point = try #require(mapping.pagePoint(forGlobal: CGPoint(x: area.midX, y: area.midY)))
        #expect(isClose(point.x, (393.0 / 2 - 50) / 393))
        #expect(isClose(point.y, 0.5))
    }

    @Test func outsideCardIsNil() {
        let mapping = CanvasMapping(area: area, viewport: CanvasViewport())
        #expect(mapping.pagePoint(forGlobal: CGPoint(x: area.midX, y: area.maxY + 20)) == nil)
    }

    @Test func zoomedCardOutsideAreaIsNil() {
        // Büyütülmüş kartın alandan taşan kısmı görünmüyor; oraya bırakılamaz.
        let mapping = CanvasMapping(area: area, viewport: CanvasViewport(zoom: 2))
        #expect(mapping.pagePoint(forGlobal: CGPoint(x: area.midX, y: area.minY - 10)) == nil)
    }

    // MARK: - Bırakılan yere ekleme

    @Test func droppedElementIsCenteredOnPoint() throws {
        let editor = try editor()
        editor.addElement(of: .button, centeredAt: CGPoint(x: 0.5, y: 0.6))
        let frame = try #require(editor.selectedElement).frame
        #expect(isClose(frame.x + frame.width / 2, 0.5))
        #expect(isClose(frame.y + frame.height / 2, 0.6))
    }

    @Test func droppedElementStaysInsideSides() throws {
        let editor = try editor()
        editor.addElement(of: .button, centeredAt: CGPoint(x: 0.99, y: 0.01))
        let frame = try #require(editor.selectedElement).frame
        #expect(isClose(frame.x + frame.width, 1))
        #expect(isClose(frame.y, 0))

        editor.addElement(of: .button, centeredAt: CGPoint(x: 0.01, y: 0.5))
        #expect(isClose(try #require(editor.selectedElement).frame.x, 0))
    }

    @Test func droppedBelowFirstScreen() throws {
        let editor = try editor()
        editor.addElement(of: .box, centeredAt: CGPoint(x: 0.5, y: 1.4))
        let frame = try #require(editor.selectedElement).frame
        #expect(isClose(frame.y + frame.height / 2, 1.4))
    }

    @Test func droppedBarKeepsItsPlace() throws {
        let editor = try editor()
        let expected = try #require(editor.catalog.makeElement(of: .tabBar)).frame
        editor.addElement(of: .tabBar, centeredAt: CGPoint(x: 0.2, y: 0.3))
        #expect(try #require(editor.selectedElement).frame == expected)
    }

    @Test func droppedSymbolIsCenteredOnPoint() throws {
        let editor = try editor()
        editor.addSymbol(named: "star.fill", centeredAt: CGPoint(x: 0.3, y: 0.4))
        let element = try #require(editor.selectedElement)
        #expect(element.properties.symbolName == "star.fill")
        #expect(isClose(element.frame.x + element.frame.width / 2, 0.3))
        #expect(isClose(element.frame.y + element.frame.height / 2, 0.4))
    }

    @Test func tapStillAddsToVisibleArea() throws {
        let editor = try editor()
        let expected = try #require(editor.catalog.makeElement(of: .button)).frame
        editor.visibleTop = 1
        editor.addElement(of: .button)
        #expect(isClose(try #require(editor.selectedElement).frame.y, expected.y + 1))
    }
}
