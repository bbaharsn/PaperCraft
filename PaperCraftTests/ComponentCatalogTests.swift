//
//  ComponentCatalogTests.swift
//  PaperCraftTests
//

import Testing
@testable import PaperCraft

@MainActor
struct ComponentCatalogTests {

    @Test func categoriesFollowDesignTabOrder() throws {
        let catalog = try ComponentCatalog.load()
        #expect(catalog.categories == ["Temel", "Form", "Navigasyon", "Medya"])
    }

    @Test func everyComponentAppearsInExactlyOneCategory() throws {
        let catalog = try ComponentCatalog.load()
        let grouped = catalog.categories.flatMap { catalog.components(in: $0) }
        #expect(grouped.count == catalog.components.count)
        #expect(catalog.components(in: "Temel").map(\.type) == [.text, .button])
    }

    @Test func emptyCatalogHasNoCategories() {
        #expect(ComponentCatalog.empty.categories.isEmpty)
    }
}
