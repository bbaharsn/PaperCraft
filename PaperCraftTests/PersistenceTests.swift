//
//  PersistenceTests.swift
//  PaperCraftTests
//

import Foundation
import SwiftData
import Testing
@testable import PaperCraft

@MainActor
struct PersistenceTests {

    /// Her test diske dokunmayan, bellekte bir veritabanı kullanır.
    /// Kap testin kendisinde tutulur: kap bellekten silinirse context'i kullanmak uygulamayı çökertir.
    private let container: ModelContainer

    init() throws {
        container = try ModelContainer(for: Project.self, ScreenRecord.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func makeContext() throws -> ModelContext {
        container.mainContext
    }

    private func loginScreen() throws -> PrototypeScreen {
        MockScreens.login(using: try ComponentCatalog.load())
    }

    @Test func createdProjectKeepsItsScreen() throws {
        let context = try makeContext()
        let screen = try loginScreen()

        let project = Project.create(name: "Kahve Dükkanı", screen: screen, in: context)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Project>()).first)
        #expect(fetched.name == "Kahve Dükkanı")
        #expect(fetched.firstScreen == screen)
        #expect(project.sortedScreens.count == 1)
    }

    @Test func savingScreenUpdatesRecordAndDate() throws {
        let context = try makeContext()
        let project = Project.create(name: "Test", screen: PrototypeScreen(name: "Ekran 1"), in: context)
        let before = project.updatedAt
        var screen = try loginScreen()
        screen.elements[0].properties.text = "Menü"

        project.saveFirstScreen(screen)

        #expect(project.firstScreen.elements[0].properties.text == "Menü")
        #expect(project.updatedAt >= before)
        #expect(project.sortedScreens.count == 1)   // yeni kayıt açılmaz, eskisi güncellenir
    }

    @Test func corruptRecordOpensAsEmptyScreen() throws {
        let context = try makeContext()
        let project = Project.create(name: "Bozuk", screen: try loginScreen(), in: context)
        project.sortedScreens.first?.data = Data("bozuk veri".utf8)

        #expect(project.firstScreen.elements.isEmpty)
    }

    @Test func deletingProjectDeletesItsScreens() throws {
        let context = try makeContext()
        let project = Project.create(name: "Silinecek", screen: try loginScreen(), in: context)
        try context.save()

        context.delete(project)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Project>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ScreenRecord>()) == 0)
    }

    @Test func newProjectNamesDoNotRepeat() {
        #expect(Project.uniqueName("Yeni Proje", existing: []) == "Yeni Proje")
        #expect(Project.uniqueName("Yeni Proje", existing: ["Yeni Proje"]) == "Yeni Proje 2")
        #expect(Project.uniqueName("Yeni Proje", existing: ["Yeni Proje", "Yeni Proje 2"]) == "Yeni Proje 3")
    }

    @Test func editorChangesCanBeSavedAndReopened() throws {
        let context = try makeContext()
        let project = Project.create(name: "Test", screen: PrototypeScreen(name: "Ekran 1"), in: context)

        // Editörde bir buton ekleyip kaydet (EditorView'ın onChange'i bunu yapar)
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: project.firstScreen)
        editor.addElement(of: .button)
        project.saveFirstScreen(editor.screen)

        // Yeniden açınca buton orada
        let reopened = EditorViewModel(catalog: try ComponentCatalog.load(), screen: project.firstScreen)
        #expect(reopened.screen.elements.map(\.type) == [.button])
    }
}
