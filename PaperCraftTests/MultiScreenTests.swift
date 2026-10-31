//
//  MultiScreenTests.swift
//  PaperCraftTests
//

import Foundation
import SwiftData
import Testing
@testable import PaperCraft

@MainActor
struct MultiScreenTests {

    /// Kap testin kendisinde tutulur: kap bellekten silinirse context'i kullanmak uygulamayı çökertir.
    private let container: ModelContainer

    init() throws {
        container = try ModelContainer(for: Project.self, ScreenRecord.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func makeProject() -> Project {
        Project.create(name: "Test", screen: PrototypeScreen(name: "Sayfa 1"), in: container.mainContext)
    }

    @Test func newPagesGoToTheEndWithTheNextNumber() {
        let project = makeProject()

        project.addScreen()
        project.addScreen()

        #expect(project.previewScreens.map(\.name) == ["Sayfa 1", "Sayfa 2", "Sayfa 3"])
    }

    @Test func pageNumberSkipsNamesInUse() {
        let project = makeProject()
        project.renameScreen(project.sortedScreens[0], to: "Sayfa 2")

        project.addScreen()

        #expect(project.previewScreens.map(\.name) == ["Sayfa 2", "Sayfa 3"])
    }

    @Test func emptyNameKeepsTheOldOne() {
        let project = makeProject()

        project.renameScreen(project.sortedScreens[0], to: "   ")

        #expect(project.firstScreen.name == "Sayfa 1")
    }

    @Test func savingAPageLeavesOthersAlone() throws {
        let project = makeProject()
        let second = project.addScreen()
        var screen = try #require(second.screen)
        screen.name = "Profil"

        project.save(screen, to: second)

        #expect(project.previewScreens.map(\.name) == ["Sayfa 1", "Profil"])
    }

    @Test func lastPageCannotBeDeleted() {
        let project = makeProject()

        project.deleteScreen(project.sortedScreens[0], in: container.mainContext)

        #expect(project.sortedScreens.count == 1)
    }

    @Test func deletingAPageRemovesLinksToIt() throws {
        let project = makeProject()
        let target = project.addScreen()
        let targetID = try #require(target.screen?.id)
        let first = project.sortedScreens[0]
        var screen = try #require(first.screen)
        screen.elements = [CanvasElement.linkedButton(to: .goTo(screenID: targetID)),
                           CanvasElement.linkedButton(to: .back)]
        project.save(screen, to: first)

        project.deleteScreen(target, in: container.mainContext)

        let actions = project.previewScreens[0].elements.map(\.properties.action)
        #expect(actions == [ElementAction.none, ElementAction.back])
        #expect(project.sortedScreens.count == 1)
    }

    @Test func removingLinksCoversTabs() {
        let target = UUID()
        var tabBar = try! ComponentCatalog.load().makeElement(of: .tabBar)!
        tabBar.properties.items = [TabItem(text: "A", symbolName: "house", action: .goTo(screenID: target)),
                                   TabItem(text: "B", symbolName: "person", action: .back)]
        var screen = PrototypeScreen(name: "Test", elements: [tabBar])

        screen.removeLinks(to: target)

        #expect(screen.elements[0].properties.items?.map(\.action) == [ElementAction.none, ElementAction.back])
    }

    @Test func oldTabsWithoutActionStillLoad() throws {
        let data = Data(#"{"text":"Ana Sayfa","symbolName":"house"}"#.utf8)

        let item = try JSONDecoder().decode(TabItem.self, from: data)

        #expect(item.action == nil)
    }

    @Test func catalogSymbolHasDefaults() throws {
        let symbol = try #require(try ComponentCatalog.load().makeElement(of: .symbol))

        #expect(symbol.type == .symbol)
        #expect(symbol.properties.symbolName == "heart")
        #expect(symbol.properties.tintColor == "#111111")
    }

    @Test func symbolHasPropertiesAndCanBeDuplicated() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))

        editor.addElement(of: .symbol)

        #expect(ElementPropertiesSheet.hasSheet(for: .symbol))
        #expect(editor.canDuplicateSelected)
    }

    @Test func addedSymbolUsesTheChosenName() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))

        editor.addSymbol(named: "star")

        #expect(editor.screen.elements.count == 1)
        #expect(editor.selectedElement?.type == .symbol)
        #expect(editor.selectedElement?.properties.symbolName == "star")
    }

    @Test func symbolLinkIsRemovedWithItsPage() throws {
        let target = UUID()
        var symbol = try #require(try ComponentCatalog.load().makeElement(of: .symbol))
        symbol.properties.action = .goTo(screenID: target)
        var screen = PrototypeScreen(name: "Test", elements: [symbol])

        screen.removeLinks(to: target)

        #expect(screen.elements[0].properties.action == ElementAction.none)
    }

    @Test func actionSurvivesSaving() throws {
        let id = UUID()
        var properties = ElementProperties()
        properties.action = .goTo(screenID: id)

        let data = try JSONEncoder().encode(properties)
        let decoded = try JSONDecoder().decode(ElementProperties.self, from: data)

        #expect(decoded.action == .goTo(screenID: id))
    }
}

private extension CanvasElement {
    static func linkedButton(to action: ElementAction) -> CanvasElement {
        var element = try! ComponentCatalog.load().makeElement(of: .button)!
        element.properties.action = action
        return element
    }
}
