//
//  CanvasViewportTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Testing
@testable import PaperCraft

struct CanvasViewportTests {

    /// Kart alana tam sığıyor: yükseklik dolu, yanlarda boşluk var.
    private let card = CGSize(width: 300, height: 650)
    private let area = CGSize(width: 360, height: 650)

    @Test func startsFittedAndCentered() {
        let viewport = CanvasViewport()
        #expect(viewport.zoom == 1)
        #expect(viewport.pan == .zero)
        #expect(!viewport.isZoomed)
    }

    @Test func pinchStaysWithinZoomRange() {
        let bigger = CanvasViewport.pinched(from: CanvasViewport(), magnification: 10, anchor: .zero,
                                            cardSize: card, available: area)
        #expect(bigger.zoom == 4)

        let smaller = CanvasViewport.pinched(from: bigger, magnification: 0.01, anchor: .zero,
                                             cardSize: card, available: area)
        #expect(smaller.zoom == 1)
        #expect(smaller.pan == .zero)
    }

    @Test func pinchAroundCenterDoesNotPan() {
        let viewport = CanvasViewport.pinched(from: CanvasViewport(), magnification: 2, anchor: .zero,
                                              cardSize: card, available: area)
        #expect(viewport.zoom == 2)
        #expect(viewport.pan == .zero)
    }

    /// Parmaklar sağ üstteyse kart sola ve aşağı kayar; o nokta parmakların altında kalır.
    @Test func pinchKeepsAnchorUnderFingers() {
        let anchor = CGPoint(x: 100, y: -200)
        let viewport = CanvasViewport.pinched(from: CanvasViewport(), magnification: 2, anchor: anchor,
                                              cardSize: card, available: area)
        #expect(viewport.pan == CGSize(width: -100, height: 200))
    }

    /// 2 katında kart 600 × 1300; alan 360 × 650. Kenara kadar + 40 point kaydırılabilir.
    @Test func dragStopsAtCardEdge() {
        let zoomed = CanvasViewport(zoom: 2)
        let viewport = CanvasViewport.dragged(from: zoomed, by: CGSize(width: 1000, height: -1000),
                                              cardSize: card, available: area, scale: 1, contentHeight: 1)
        #expect(viewport.pan == CGSize(width: 160, height: -365))
    }

    @Test func fittedCardCannotBeDragged() {
        let viewport = CanvasViewport.dragged(from: CanvasViewport(), by: CGSize(width: 50, height: 50),
                                              cardSize: card, available: area, scale: 1, contentHeight: 1)
        #expect(viewport.pan == .zero)
    }

    // MARK: - Sayfa kaydırma

    /// Sığdırılmış kartta parmak 200 pt yukarı → sayfa 200 / 0.8 = 250 tuval point'i aşağı iner.
    @Test func fittedDragScrollsPage() {
        let viewport = CanvasViewport.dragged(from: CanvasViewport(), by: CGSize(width: 0, height: -200),
                                              cardSize: card, available: area, scale: 0.8, contentHeight: 3)
        #expect(viewport.pan == .zero)
        #expect(abs(viewport.scroll - 250) < 0.001)
    }

    @Test func scrollStopsAtTop() {
        let start = CanvasViewport(scroll: 100)
        let viewport = CanvasViewport.dragged(from: start, by: CGSize(width: 0, height: 500),
                                              cardSize: card, available: area, scale: 1, contentHeight: 3)
        #expect(viewport.scroll == 0)
    }

    /// Tek ekranlık sayfa bir boş ekran daha (852 pt) kaydırılabilir, fazlası değil.
    @Test func scrollStopsOneScreenBelowContent() {
        let viewport = CanvasViewport.dragged(from: CanvasViewport(), by: CGSize(width: 0, height: -5000),
                                              cardSize: card, available: area, scale: 1, contentHeight: 1)
        #expect(viewport.scroll == 852)
    }

    /// 2 katında kart aşağı 365 pt kayabilir; parmak 500 pt yukarı → kart sınırına gelir, kalan 135 pt sayfayı kaydırır.
    @Test func zoomedDragPansThenScrolls() {
        let viewport = CanvasViewport.dragged(from: CanvasViewport(zoom: 2), by: CGSize(width: 0, height: -500),
                                              cardSize: card, available: area, scale: 2, contentHeight: 3)
        #expect(viewport.pan.height == -365)
        #expect(abs(viewport.scroll - 135.0 / 2) < 0.001)
    }

    @Test func pinchKeepsScroll() {
        let viewport = CanvasViewport.pinched(from: CanvasViewport(scroll: 300), magnification: 2, anchor: .zero,
                                              cardSize: card, available: area)
        #expect(viewport.scroll == 300)
    }
}
