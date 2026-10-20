//
//  TextFieldStyleTests.swift
//  PaperCraftTests
//

import Foundation
import Testing
@testable import PaperCraft

@MainActor
struct TextFieldStyleTests {

    @Test func catalogTextFieldHasStyleDefaults() throws {
        let field = try #require(try ComponentCatalog.load().makeElement(of: .textField))

        #expect(field.properties.border == .roundedBorder)
        #expect(field.properties.inputKind == .plain)
        #expect(field.properties.iconPosition == IconPosition.none)
        #expect(field.properties.fillColor == "#C7C7CC")
        #expect(field.properties.contentColor == "#111111")
    }

    @Test func unknownTextFieldValuesFallBackInsteadOfCrashing() throws {
        let json = #"{ "border": "zigzag", "inputKind": "telepathy" }"#
        let properties = try JSONDecoder().decode(ElementProperties.self, from: Data(json.utf8))

        #expect(properties.border == .roundedBorder)
        #expect(properties.inputKind == .plain)
    }

    @Test func textFieldResizeRespectsItsOwnMinimumSize() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .textField)

        editor.setSelectedSize(width: 10, height: 10)

        let size = editor.pointRect(of: try #require(editor.selectedElement)).size
        #expect(abs(size.width - 80) < 0.001 && abs(size.height - 34) < 0.001)   // katalogdaki minSize
    }
}
