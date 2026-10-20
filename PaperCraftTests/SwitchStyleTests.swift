//
//  SwitchStyleTests.swift
//  PaperCraftTests
//

import Foundation
import SwiftUI
import Testing
@testable import PaperCraft

@MainActor
struct SwitchStyleTests {

    @Test func catalogSwitchHasStyleDefaults() throws {
        let toggle = try #require(try ComponentCatalog.load().makeElement(of: .switch))

        #expect(toggle.properties.text == "Option")
        #expect(toggle.properties.isOn == true)
        #expect(toggle.properties.labelPosition == .leading)
        #expect(toggle.properties.fillColor == "#34C759")
        #expect(toggle.properties.contentColor == "#111111")
    }

    @Test func unknownLabelPositionFallsBackInsteadOfCrashing() throws {
        // "hidden" eskiden bir seçenekti; artık tanınmıyor ve varsayılana düşmeli
        let json = #"{ "labelPosition": "hidden" }"#
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))

        #expect(properties.labelPosition == .leading)
    }

    @Test func togglingIsOnUpdatesSelectedSwitch() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .switch)

        editor.binding(\.isOn, default: false).wrappedValue = false

        #expect(editor.selectedElement?.properties.isOn == false)
    }
}
