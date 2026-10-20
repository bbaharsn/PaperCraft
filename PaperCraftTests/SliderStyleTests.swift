//
//  SliderStyleTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import Testing
@testable import PaperCraft

@MainActor
struct SliderStyleTests {

    private func makeEditorWithSlider() throws -> EditorViewModel {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .slider)
        return editor
    }

    private func width(in editor: EditorViewModel) throws -> CGFloat {
        editor.pointRect(of: try #require(editor.selectedElement)).width
    }

    @Test func catalogSliderHasStyleDefaults() throws {
        let slider = try #require(try ComponentCatalog.load().makeElement(of: .slider))

        #expect(slider.properties.sliderRange == 0...1)
        #expect(slider.properties.value == 0.5)
        #expect(slider.properties.fillColor == "#007AFF")
        #expect(slider.properties.showsSideIcons == false)
        #expect(slider.properties.minSymbolName == "minus")
        #expect(slider.properties.maxSymbolName == "plus")
        #expect(slider.properties.showsValue == false)
    }

    @Test func reversedOrEqualRangeDoesNotCrash() throws {
        let json = #"{ "value": 500, "minValue": 10, "maxValue": 10 }"#
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))

        #expect(properties.sliderRange == 10...11)
        #expect(properties.sliderValue == 11)   // aralığın içine çekildi

        let reversed = ElementProperties(minValue: 100, maxValue: 0)
        #expect(reversed.sliderRange == 0...100)
    }

    @Test func sideIconsWidenAndNarrowTheFrame() throws {
        let editor = try makeEditorWithSlider()
        let before = try width(in: editor)

        editor.setSelectedSliderShowsSideIcons(true)
        let iconsWidth = 2 * (SliderLayout.iconWidth + SliderLayout.spacing)
        #expect(abs(try width(in: editor) - (before + iconsWidth)) < 0.001)

        editor.setSelectedSliderShowsSideIcons(false)
        #expect(abs(try width(in: editor) - before) < 0.001)
    }

    @Test func valueLabelWidensTheFrame() throws {
        let editor = try makeEditorWithSlider()
        let before = try width(in: editor)

        editor.setSelectedSliderShowsValue(true)

        #expect(abs(try width(in: editor) - (before + SliderLayout.valueWidth + SliderLayout.spacing)) < 0.001)
        #expect(editor.selectedElement?.properties.showsValue == true)
    }

    @Test func widenedSliderStaysOnScreen() throws {
        let editor = try makeEditorWithSlider()
        editor.setSelectedSize(width: 10_000, height: 44)   // ekranın sağ kenarına kadar

        editor.setSelectedSliderShowsSideIcons(true)

        let rect = editor.pointRect(of: try #require(editor.selectedElement))
        #expect(rect.minX >= -0.001)
        #expect(rect.maxX <= editor.catalog.referenceCanvas.width + 0.001)
    }

    @Test func minimumWidthGrowsWithSideIcons() throws {
        let editor = try makeEditorWithSlider()
        editor.setSelectedSliderShowsSideIcons(true)

        editor.setSelectedSize(width: 10, height: 44)

        let iconsWidth = 2 * (SliderLayout.iconWidth + SliderLayout.spacing)
        #expect(abs(try width(in: editor) - (80 + iconsWidth)) < 0.001)   // katalogdaki minSize + ikonlar
    }

    @Test func rangeKeepsMinBelowMaxAndClampsValue() throws {
        let editor = try makeEditorWithSlider()

        editor.setSelectedSliderRange(min: 0, max: 100)
        editor.updateSelectedProperties { $0.value = 80 }
        editor.setSelectedSliderRange(min: 0, max: 50)
        #expect(editor.selectedElement?.properties.value == 50)

        editor.setSelectedSliderRange(min: 70, max: 50)   // alt sınır üstü geçti
        #expect(editor.selectedElement?.properties.sliderRange == 70...71)

        editor.setSelectedSliderRange(min: 70, max: 60)   // üst sınır altın altına indi
        #expect(editor.selectedElement?.properties.sliderRange == 59...60)
    }
}
