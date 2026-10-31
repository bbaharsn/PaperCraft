//
//  ScreenBackgroundTests.swift
//  PaperCraftTests
//

import Foundation
import SwiftUI
import Testing
@testable import PaperCraft

@MainActor
struct ScreenBackgroundTests {

    private func makeEditor() throws -> EditorViewModel {
        EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
    }

    @Test func oldScreensWithoutBackgroundStillLoad() throws {
        let data = Data(#"{"id":"\#(UUID().uuidString)","name":"Eski","elements":[]}"#.utf8)

        let screen = try JSONDecoder().decode(PrototypeScreen.self, from: data)

        #expect(screen.background == nil)
    }

    @Test func missingFieldsFallBackToDefaults() throws {
        let data = Data(##"{"color":"#FFFFFF"}"##.utf8)

        let background = try JSONDecoder().decode(ScreenBackground.self, from: data)

        #expect(background.color == "#FFFFFF")
        #expect(background.kind == .solid)
        #expect(background.direction == .vertical)
    }

    @Test func unknownValuesFallBackToDefaults() throws {
        let data = Data(#"{"kind":"rainbow","direction":"spiral"}"#.utf8)

        let background = try JSONDecoder().decode(ScreenBackground.self, from: data)

        #expect(background.kind == .solid)
        #expect(background.direction == .vertical)
    }

    @Test func kindDecidesTheDrawnColors() {
        var background = ScreenBackground(color: "#111111", middleColor: "#222222", endColor: "#333333")

        #expect(background.colors == ["#111111"])

        background.kind = .twoColors
        #expect(background.colors == ["#111111", "#333333"])

        background.kind = .threeColors
        #expect(background.colors == ["#111111", "#222222", "#333333"])
    }

    @Test func backgroundSurvivesSaving() throws {
        var screen = PrototypeScreen(name: "Test")
        screen.background = ScreenBackground(kind: .threeColors, color: "#FFD6E0", middleColor: "#C7F0D8",
                                             endColor: "#BDE0FE", direction: .diagonal)

        let data = try JSONEncoder().encode(screen)
        let decoded = try JSONDecoder().decode(PrototypeScreen.self, from: data)

        #expect(decoded.background == screen.background)
    }

    @Test func firstChangeCreatesTheBackground() throws {
        let editor = try makeEditor()

        editor.backgroundBinding(\.color).wrappedValue = "#007AFF"

        #expect(editor.screen.background?.color == "#007AFF")
        #expect(editor.screen.background?.kind == .solid)
    }

    @Test func backgroundChangeCanBeUndone() throws {
        let editor = try makeEditor()

        editor.backgroundBinding(\.kind).wrappedValue = .twoColors
        editor.undo()

        #expect(editor.screen.background == nil)
    }

    @Test func turningGradientOffKeepsItsColors() throws {
        let editor = try makeEditor()
        editor.backgroundBinding(\.middleColor).wrappedValue = "#C7F0D8"
        editor.backgroundBinding(\.endColor).wrappedValue = "#BDE0FE"

        editor.backgroundBinding(\.kind).wrappedValue = .threeColors
        editor.backgroundBinding(\.kind).wrappedValue = .solid

        #expect(editor.screen.background?.middleColor == "#C7F0D8")
        #expect(editor.screen.background?.endColor == "#BDE0FE")
    }
}
