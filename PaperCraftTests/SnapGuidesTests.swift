//
//  SnapGuidesTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Testing
@testable import PaperCraft

struct SnapGuidesTests {

    private let pageWidth: CGFloat = 393

    /// Ortası 196.5'ten 4 point solda olan 100 genişliğinde eleman.
    private func rect(midX: CGFloat) -> CGRect {
        CGRect(x: midX - 50, y: 200, width: 100, height: 40)
    }

    @Test func snapsToPageCenterWithinTolerance() {
        let result = SnapGuides.snapMove(rect(midX: 192.5), pageWidth: pageWidth, tolerance: 6)
        #expect(result.offset == CGSize(width: 4, height: 0))
        #expect(result.guides == [SnapGuide(axis: .vertical, position: 196.5)])
    }

    @Test func snapsFromTheOtherSideToo() {
        let result = SnapGuides.snapMove(rect(midX: 201), pageWidth: pageWidth, tolerance: 6)
        #expect(result.offset.width == -4.5)
        #expect(result.guides.count == 1)
    }

    @Test func doesNotSnapOutsideTolerance() {
        let result = SnapGuides.snapMove(rect(midX: 180), pageWidth: pageWidth, tolerance: 6)
        #expect(result == SnapResult())
    }

    /// Yakınlaştırınca eşik küçülür; aynı uzaklık artık yapışmaz.
    @Test func smallerToleranceWhenZoomedIn() {
        let zoomed = SnapGuides.snapMove(rect(midX: 192.5), pageWidth: pageWidth,
                                         tolerance: SnapGuides.threshold / 2)
        #expect(zoomed.guides.isEmpty)
    }

    // MARK: - Diğer elemanlarla aynı kenar

    /// Taşınan eleman: x 20…120, y 300…340.
    private let moving = CGRect(x: 20, y: 300, width: 100, height: 40)

    @Test func snapsLeftEdgeToLeftEdge() {
        let box = CGRect(x: 24, y: 100, width: 200, height: 60)
        let result = SnapGuides.snapMove(moving, targets: [box], pageWidth: pageWidth, tolerance: 6)
        #expect(result.offset == CGSize(width: 4, height: 0))
        // Çizgi üstteki kutunun tepesinden alttaki elemanın dibine uzanır
        #expect(result.guides == [SnapGuide(axis: .vertical, position: 24, span: 100...340)])
    }

    /// Sağ kenar, orta ve üst/alt kenarlar yapışmaz; yalnızca sol kenar ve sayfa ortası.
    @Test func otherEdgesDoNotSnap() {
        let rightAligned = CGRect(x: 50, y: 100, width: 72, height: 60)  // sağ 122, taşınanın sağı 120
        let centerAligned = CGRect(x: 40, y: 100, width: 62, height: 60) // ortası 71, taşınanın 70
        let topAligned = CGRect(x: 250, y: 302, width: 100, height: 38)  // üst 302, alt 340
        let result = SnapGuides.snapMove(moving, targets: [rightAligned, centerAligned, topAligned],
                                         pageWidth: pageWidth, tolerance: 6)
        #expect(result == SnapResult())
    }

    @Test func picksTheClosestAlignment() {
        let far = CGRect(x: 25, y: 0, width: 50, height: 50)   // sol 5 uzakta
        let near = CGRect(x: 22, y: 600, width: 50, height: 50) // sol 2 uzakta
        let result = SnapGuides.snapMove(moving, targets: [far, near], pageWidth: pageWidth, tolerance: 6)
        #expect(result.offset.width == 2)
        #expect(result.guides.map(\.position) == [22])
    }

    /// Aynı sol kenardaki elemanların hepsi tek çizgide kapsanır.
    @Test func lineCoversEveryElementOnThatEdge() {
        let above = CGRect(x: 23, y: 100, width: 50, height: 40)
        let below = CGRect(x: 23, y: 500, width: 80, height: 40)
        let result = SnapGuides.snapMove(moving, targets: [above, below], pageWidth: pageWidth, tolerance: 6)
        #expect(result.guides == [SnapGuide(axis: .vertical, position: 23, span: 100...540)])
    }

    /// Ekranın sol kenarına dayalı üst bar hedef değil; ekran kenarına yapışma olmasın.
    @Test func ignoresElementsOnThePageBorder() {
        let bar = CGRect(x: 0, y: 0, width: 393, height: 96)
        let nearLeft = CGRect(x: 3, y: 300, width: 100, height: 40)
        #expect(SnapGuides.snapMove(nearLeft, targets: [bar], pageWidth: pageWidth, tolerance: 6).guides.isEmpty)
    }

    @Test func boundingBoxOfQuarterTurnSwapsSides() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 40)
        let turned = SnapGuides.boundingBox(rect, degrees: 90)
        #expect(abs(turned.width - 40) < 0.001)
        #expect(abs(turned.height - 100) < 0.001)
        #expect(abs(turned.midX - 50) < 0.001 && abs(turned.midY - 20) < 0.001)
        #expect(SnapGuides.boundingBox(rect, degrees: 0) == rect)
    }

    @Test func alreadyCenteredShowsLineWithoutMoving() {
        let result = SnapGuides.snapMove(rect(midX: 196.5), pageWidth: pageWidth, tolerance: 6)
        #expect(result.offset == .zero)
        #expect(result.guides.count == 1)
    }
}
