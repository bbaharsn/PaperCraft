//
//  RotationTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import Testing
@testable import PaperCraft

@MainActor
struct RotationTests {

    private func makeEditor() throws -> EditorViewModel {
        EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
    }

    /// Normalize ↔ point dönüşümünde küçük yuvarlama farkları olabilir.
    private func isClose(_ a: CGFloat, _ b: CGFloat) -> Bool {
        abs(a - b) < 0.001
    }

    // MARK: - Üstte olan

    @Test func touchedElementComesToFront() throws {
        let editor = try makeEditor()
        editor.addElement(of: .image)
        let first = try #require(editor.selectedElementID)
        editor.addElement(of: .image)
        let second = try #require(editor.selectedElementID)
        #expect(editor.screen.elements.last?.id == second)

        editor.select(first)

        #expect(editor.screen.elements.map(\.id) == [second, first])
    }

    @Test func deselectingKeepsOrder() throws {
        let editor = try makeEditor()
        editor.addElement(of: .image)
        editor.addElement(of: .button)
        let order = editor.screen.elements.map(\.id)

        editor.select(nil)

        #expect(editor.screen.elements.map(\.id) == order)
    }

    // MARK: - Açı

    @Test func rotationIsKeptBetween0And360() throws {
        let editor = try makeEditor()
        editor.addElement(of: .image)
        let id = try #require(editor.selectedElementID)

        editor.setRotation(id, degrees: -90)
        #expect(editor.selectedElement?.properties.rotation == 270)

        editor.setRotation(id, degrees: 450)
        #expect(editor.selectedElement?.properties.rotation == 90)
    }

    @Test func rotationSnapsNearRightAngles() {
        #expect(EditorViewModel.snappedRotation(87) == 90)
        #expect(EditorViewModel.snappedRotation(-3) == 0)
        #expect(EditorViewModel.snappedRotation(183) == 180)
        #expect(EditorViewModel.snappedRotation(45) == 45)
    }

    @Test func unrotatedElementHasNoAngle() throws {
        let image = try #require(try ComponentCatalog.load().makeElement(of: .image))
        #expect(image.properties.rotation == nil)
    }

    // MARK: - Döndürülmüş elemanı boyutlandırma

    @Test func resizingRotatedElementFollowsItsOwnAxes() throws {
        let editor = try makeEditor()
        editor.addElement(of: .image)   // 200 × 150
        let id = try #require(editor.selectedElementID)
        editor.setRotation(id, degrees: 90)

        // 90° dönmüş görselde ekranda aşağı çekmek, görselin kendi genişliğini artırır
        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: 0, height: 20))

        let rect = editor.pointRect(of: try #require(editor.selectedElement))
        #expect(isClose(rect.width, 220) && isClose(rect.height, 150))
    }

    @Test func resizingRotatedElementKeepsOppositeCornerOnScreen() throws {
        let editor = try makeEditor()
        editor.addElement(of: .image)
        let id = try #require(editor.selectedElementID)
        editor.setRotation(id, degrees: 90)

        /// Sol üst köşenin (çekilen sağ alt köşenin karşısı) ekrandaki yeri
        func anchorOnScreen() throws -> CGPoint {
            let rect = editor.pointRect(of: try #require(editor.selectedElement))
            // 90°'de (x, y) → (-y, x)
            let dx = rect.minX - rect.midX, dy = rect.minY - rect.midY
            return CGPoint(x: rect.midX - dy, y: rect.midY + dx)
        }
        let before = try anchorOnScreen()

        editor.resizeElement(id, from: .bottomTrailing, by: CGSize(width: -30, height: 40))

        let after = try anchorOnScreen()
        #expect(isClose(before.x, after.x) && isClose(before.y, after.y))
    }
}
