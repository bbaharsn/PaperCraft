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

    // MARK: - Kayan sayfa

    /// Tek ekranlık sayfa kayan yerleşime geçmez; konumlar eskisi gibi durum çubuğunun altına yayılır.
    @Test func shortPageUsesStretchedLayout() {
        let screen = PrototypeScreen(name: "Kısa", elements: [
            CanvasElement(type: .box, frame: NormalizedFrame(x: 0, y: 0.9, width: 0.5, height: 0.1),
                          properties: ElementProperties())
        ])
        #expect(screen.contentHeight(screenHeight: 852) == 1)

        let layout = PreviewLayout(stageSize: CGSize(width: 390, height: 844), topInset: 47)
        let frame = screen.elements[0].frame
        // En alttaki eleman, durum çubuğunun altındaki alanın en altına oturur
        #expect(abs(layout.center(of: frame).y - (layout.designHeight - 85.2 / 2)) < 0.01)
    }

    @Test func scrollingCenterUsesCanvasPoints() {
        let layout = PreviewLayout(stageSize: CGSize(width: 390, height: 844), topInset: 47)
        let center = layout.scrollingCenter(of: NormalizedFrame(x: 0.25, y: 1.5, width: 0.5, height: 0.1))

        #expect(abs(center.x - 196.5) < 0.01)
        #expect(abs(center.y - (1.5 * 852 + 42.6)) < 0.01)
    }

    @Test func scrollingContentIsAtLeastScreenTall() {
        let layout = PreviewLayout(stageSize: CGSize(width: 390, height: 844), topInset: 47)
        let empty = PrototypeScreen(name: "Boş")
        let long = PrototypeScreen(name: "Uzun", elements: [
            CanvasElement(type: .box, frame: NormalizedFrame(x: 0, y: 2, width: 0.5, height: 0.5),
                          properties: ElementProperties())
        ])

        // Boş sayfa bir ekran (852) sayılır; bu görünen alandan (≈803) uzun
        #expect(layout.scrollingContentHeight(for: empty) == max(layout.designHeight, 852))
        #expect(abs(layout.scrollingContentHeight(for: long) - (2.5 * 852 + 24)) < 0.01)
    }

    // MARK: - iPad'de iPhone projesi: telefon çerçevesi

    private let phone = CGSize(width: 393, height: 852)
    private let iPadDesign = CGSize(width: 820, height: 1180)

    @Test func phoneDesignIsFramedOnIPad() {
        #expect(PreviewLayout.showsDeviceFrame(for: CGSize(width: 1032, height: 1376), reference: phone))   // iPad Pro 13" dik
        #expect(PreviewLayout.showsDeviceFrame(for: CGSize(width: 1376, height: 1032), reference: phone))   // yatay
        #expect(PreviewLayout.showsDeviceFrame(for: CGSize(width: 1133, height: 744), reference: phone))    // iPad mini yatay
    }

    @Test func phoneItselfIsNeverFramed() {
        #expect(!PreviewLayout.showsDeviceFrame(for: CGSize(width: 390, height: 844), reference: phone))
        #expect(!PreviewLayout.showsDeviceFrame(for: CGSize(width: 844, height: 390), reference: phone))    // yatay telefon
    }

    @Test func iPadDesignIsNeverFramed() {
        #expect(!PreviewLayout.showsDeviceFrame(for: CGSize(width: 1032, height: 1376), reference: iPadDesign))
    }

    @Test func framedPhoneIsRealSizeWhenItFits() {
        #expect(PreviewLayout.deviceFrameScale(for: CGSize(width: 1032, height: 1376), reference: phone) == 1)
    }

    @Test func framedPhoneShrinksButNeverGrows() {
        // iPad mini yatay: 744 - 2·40 = 664 pt yükseklik var
        let scale = PreviewLayout.deviceFrameScale(for: CGSize(width: 1133, height: 744), reference: phone)
        #expect(abs(scale - 664.0 / 852.0) < 0.0001)
        #expect(PreviewLayout.deviceFrameScale(for: CGSize(width: 3000, height: 3000), reference: phone) == 1)
    }

    // MARK: - Yatay iPad tasarımı

    private let landscape = DeviceKind.iPadLandscape.canvasSize

    @Test func landscapeDesignIsFramedOnPortraitScreens() {
        #expect(PreviewLayout.showsDeviceFrame(for: CGSize(width: 1032, height: 1376), reference: landscape))  // dikey iPad
        #expect(PreviewLayout.showsDeviceFrame(for: CGSize(width: 390, height: 844), reference: landscape))    // telefon
    }

    @Test func landscapeDesignFillsLandscapeIPad() {
        #expect(!PreviewLayout.showsDeviceFrame(for: CGSize(width: 1376, height: 1032), reference: landscape)) // iPad Pro 13" yatay
        #expect(!PreviewLayout.showsDeviceFrame(for: CGSize(width: 1133, height: 744), reference: landscape))  // iPad mini yatay
    }

    @Test func framedLandscapeDesignShrinksToFitWidth() {
        // Dikey iPad Pro 13": 1032 - 2·40 = 952 pt genişlik var
        let scale = PreviewLayout.deviceFrameScale(for: CGSize(width: 1032, height: 1376), reference: landscape)
        #expect(abs(scale - 952.0 / 1180.0) < 0.0001)
    }

    @Test func frameInsetAndCornerFollowTheDevice() {
        #expect(PreviewLayout.frameTopInset(for: phone) == 59)
        #expect(PreviewLayout.frameTopInset(for: landscape) == 24)
        #expect(PreviewLayout.frameCornerRadius(for: phone) == 55)
        #expect(PreviewLayout.frameCornerRadius(for: landscape) == 18)
    }

    // MARK: - Yatay iPhone tasarımı

    private let landscapePhone = DeviceKind.iPhoneLandscape.canvasSize

    @Test func landscapePhoneIsStillAPhoneDesign() {
        #expect(PreviewLayout.isPhoneDesign(landscapePhone))
        #expect(!PreviewLayout.isPhoneDesign(landscape))
    }

    @Test func landscapePhoneIsFramedOnIPadAndPortraitPhone() {
        #expect(PreviewLayout.showsDeviceFrame(for: CGSize(width: 1376, height: 1032), reference: landscapePhone)) // yatay iPad
        #expect(PreviewLayout.showsDeviceFrame(for: CGSize(width: 1032, height: 1376), reference: landscapePhone)) // dikey iPad
        #expect(PreviewLayout.showsDeviceFrame(for: CGSize(width: 390, height: 844), reference: landscapePhone))   // dik telefon
    }

    @Test func landscapePhoneFillsLandscapePhone() {
        #expect(!PreviewLayout.showsDeviceFrame(for: CGSize(width: 844, height: 390), reference: landscapePhone))
    }

    @Test func landscapePhoneFrameHasNoStatusBar() {
        #expect(PreviewLayout.frameTopInset(for: landscapePhone) == 0)
        #expect(PreviewLayout.frameCornerRadius(for: landscapePhone) == 55)
        #expect(PreviewLayout.deviceFrameScale(for: CGSize(width: 1376, height: 1032), reference: landscapePhone) == 1)
    }
}
