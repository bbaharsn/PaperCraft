//
//  GroupResizeTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Testing
@testable import PaperCraft

struct GroupResizeTests {

    /// Grup: (100, 100) noktasında 200 × 100; sayfa 400 pt genişliğinde.
    private let rect = CGRect(x: 100, y: 100, width: 200, height: 100)

    private func scale(_ corner: ResizeCorner, _ dx: CGFloat, _ dy: CGFloat, minimum: CGFloat = 0.1) -> CGFloat {
        GroupResize.scale(dragging: corner, by: CGSize(width: dx, height: dy), rect: rect,
                          canvasWidth: 400, minimumScale: minimum)
    }

    private func isClose(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 1e-9 }

    @Test func growsByTheLargerSide() {
        #expect(isClose(scale(.bottomTrailing, 100, 0), 1.5))
    }

    @Test func shrinksByTheLargerSide() {
        #expect(isClose(scale(.bottomTrailing, -50, -50), 0.75))
    }

    @Test func stopsAtMinimumScale() {
        #expect(isClose(scale(.bottomTrailing, -190, -90, minimum: 0.5), 0.5))
    }

    @Test func stopsAtRightEdge() {
        #expect(isClose(scale(.bottomTrailing, 300, 0), 1.5))   // sağ kenar 400'ü geçmez
    }

    @Test func topLeadingStopsAtLeftAndTopEdges() {
        // Karşı köşe (300, 200): üstten 2 kat, soldan 1,5 kat yer var
        #expect(isClose(scale(.topLeading, 0, -200), 1.5))
    }

    @Test func bottomCanGrowPastTheScreen() {
        #expect(isClose(scale(.bottomLeading, 0, 300), 1.5))   // aşağı serbest; soldan 1,5 kat sınır
        #expect(isClose(GroupResize.scale(dragging: .bottomTrailing, by: CGSize(width: 0, height: 300),
                                          rect: CGRect(x: 0, y: 100, width: 100, height: 100),
                                          canvasWidth: 400, minimumScale: 0.1), 4))
    }

    @Test func anchorIsTheOppositeCorner() {
        #expect(GroupResize.anchor(of: .bottomTrailing, in: rect) == CGPoint(x: 100, y: 100))
        #expect(GroupResize.anchor(of: .topLeading, in: rect) == CGPoint(x: 300, y: 200))
    }

    @Test func scalesRectAroundAnchor() {
        let scaled = GroupResize.scaled(CGRect(x: 150, y: 120, width: 20, height: 10), by: 2,
                                        around: CGPoint(x: 100, y: 100))
        #expect(scaled == CGRect(x: 200, y: 140, width: 40, height: 20))
    }
}
