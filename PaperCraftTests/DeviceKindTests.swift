//
//  DeviceKindTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import SwiftData
import Testing
@testable import PaperCraft

@MainActor
struct DeviceKindTests {

    private let container: ModelContainer

    init() throws {
        container = try ModelContainer(for: Project.self, ScreenRecord.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func isClose(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 0.0001 }

    // MARK: - Proje

    @Test func newProjectIsIPhoneByDefault() {
        let project = Project.create(name: "Test", screen: PrototypeScreen(name: "Sayfa 1"),
                                     in: container.mainContext)
        #expect(project.device == .iPhone)
    }

    @Test func iPadProjectKeepsItsDevice() throws {
        let context = container.mainContext
        Project.create(name: "Tablet", device: .iPad, screen: PrototypeScreen(name: "Sayfa 1"), in: context)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Project>()).first)
        #expect(fetched.device == .iPad)
    }

    @Test func unknownDeviceFallsBackToIPhone() {
        let project = Project(name: "Bozuk")
        project.deviceRaw = "watch"
        #expect(project.device == .iPhone)
    }

    // MARK: - Yeni proje menüsü

    @Test func menuPutsPreferredDeviceFirst() {
        #expect(DeviceKind.menuOrder(preferred: .iPhone) == [.iPhone, .iPhoneLandscape, .iPad, .iPadLandscape])
        #expect(DeviceKind.menuOrder(preferred: .iPad) == [.iPad, .iPadLandscape, .iPhone, .iPhoneLandscape])
    }

    @Test func eachDeviceHasTitleAndSymbol() {
        #expect(DeviceKind.iPhone.title == "iPhone")
        #expect(DeviceKind.iPad.title == "iPad")
        #expect(DeviceKind.iPad.symbolName == "ipad")
        #expect(DeviceKind.iPadLandscape.title == "iPad (yatay)")
        #expect(DeviceKind.iPadLandscape.symbolName == "ipad.landscape")
        #expect(DeviceKind.iPhoneLandscape.title == "iPhone (yatay)")
        #expect(DeviceKind.iPhoneLandscape.symbolName == "iphone.landscape")
    }

    @Test func landscapeIPhoneIsTheRotatedPortraitCanvas() {
        let portrait = DeviceKind.iPhone.canvasSize
        #expect(DeviceKind.iPhoneLandscape.canvasSize == CGSize(width: portrait.height, height: portrait.width))
        #expect(DeviceKind.iPhoneLandscape.isLandscape)
        #expect(!DeviceKind.iPhoneLandscape.isPad)
        #expect(!DeviceKind.iPhone.isLandscape)
    }

    @Test func landscapeIPadIsTheRotatedPortraitCanvas() {
        let portrait = DeviceKind.iPad.canvasSize
        #expect(DeviceKind.iPadLandscape.canvasSize == CGSize(width: portrait.height, height: portrait.width))
    }

    @Test func landscapeIPadProjectIsSaved() throws {
        let project = Project(name: "Yatay", device: .iPadLandscape)
        #expect(project.deviceRaw == "iPadLandscape")
        #expect(project.device == .iPadLandscape)
    }

    // MARK: - Katalog ve editör

    @Test func iPhoneSizeIsUnchanged() throws {
        let catalog = try ComponentCatalog.load()
        #expect(catalog.sized(for: .iPhone).referenceCanvas.width == catalog.referenceCanvas.width)
        #expect(catalog.sized(for: .iPhone).referenceCanvas.height == catalog.referenceCanvas.height)
    }

    /// Aynı point boyutundaki buton iPad tuvalinde daha küçük bir oran kaplar.
    @Test func iPadElementKeepsItsPointSize() throws {
        let catalog = try ComponentCatalog.load()
        let definition = try #require(catalog.definition(for: .button))
        let editor = EditorViewModel(catalog: catalog.sized(for: .iPad), screen: PrototypeScreen(name: "Test"))
        let element = try #require(editor.catalog.makeElement(of: .button))

        #expect(editor.canvasSize == DeviceKind.iPad.canvasSize)
        let rect = editor.pointRect(of: element)
        #expect(isClose(rect.width, definition.defaultSize.width))
        #expect(isClose(rect.height, definition.defaultSize.height))
    }

    /// Üst bar ve alt menü iPad'de de tuvalin tam genişliğinde, yüksekliği aynı.
    @Test(arguments: [ElementType.navigationBar, .tabBar])
    func iPadFullWidthBarsSpanCanvas(_ type: ElementType) throws {
        let catalog = try ComponentCatalog.load()
        let iPhoneHeight = try #require(catalog.definition(for: type)).defaultSize.height
        let editor = EditorViewModel(catalog: catalog.sized(for: .iPad), screen: PrototypeScreen(name: "Test"))
        let element = try #require(editor.catalog.makeElement(of: type))

        #expect(isClose(element.frame.x, 0))
        #expect(isClose(element.frame.width, 1))
        #expect(isClose(editor.pointRect(of: element).height, iPhoneHeight))
    }

    @Test func iPhoneBarsAreUnchanged() throws {
        let catalog = try ComponentCatalog.load()
        let original = try #require(catalog.definition(for: .tabBar)).defaultSize
        let sized = try #require(catalog.sized(for: .iPhone).definition(for: .tabBar)).defaultSize
        #expect(sized.width == original.width && sized.height == original.height)
    }

    // MARK: - Canvas eşlemesi

    /// iPad tuvali, kendi oranındaki alanı tam doldurur; köşe sayfanın köşesidir.
    @Test func iPadMappingUsesIPadCanvas() throws {
        let size = DeviceKind.iPad.canvasSize
        let area = CGRect(x: 0, y: 0, width: size.width / 2, height: size.height / 2)
        let mapping = CanvasMapping(area: area, viewport: CanvasViewport(), canvasSize: size)

        #expect(isClose(mapping.scale, 0.5))
        let corner = try #require(mapping.pagePoint(forGlobal: CGPoint(x: area.maxX - 0.01, y: area.maxY - 0.01)))
        #expect(abs(corner.x - 1) < 0.001)
        #expect(abs(corner.y - 1) < 0.001)
    }

    @Test func iPadMaxScrollIsOneIPadScreen() {
        let height = DeviceKind.iPad.canvasSize.height
        #expect(CanvasViewport.maxScroll(contentHeight: 1, screenHeight: height) == height)
    }

    // MARK: - Önizleme

    @Test func iPhonePreviewStageIsUnchanged() {
        let screen = CGSize(width: 820, height: 1180)
        #expect(PreviewLayout.stageWidth(for: screen) == 1180 * 0.6)
    }

    @Test func iPadPreviewFillsIPadScreen() {
        let size = DeviceKind.iPad.canvasSize
        #expect(PreviewLayout.stageWidth(for: size, reference: size) == size.width)
    }
}
