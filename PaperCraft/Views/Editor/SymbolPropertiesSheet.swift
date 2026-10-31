//
//  SymbolPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir sembol seçiliyken alttan açılan "Özellikler" sayfasının içeriği.
struct SymbolPropertiesSheet: View {
    let viewModel: EditorViewModel

    /// Hazır renkler (siyah, koyu kahve, vurgu, mavi, yeşil, beyaz).
    private let tintPresets = ["#111111", "#2B2118", "#AC5135", "#007AFF", "#34C759", "#FFFFFF"]

    var body: some View {
        Section("Sembol") {
            SymbolPickerRow(symbolName: viewModel.binding(\.symbolName, default: "heart"),
                            symbols: viewModel.symbolCatalog.symbols)
            BoolPicker(isOn: viewModel.binding(\.isSymbolFilled, default: false), off: "Çizgi", on: "Dolu")
        }

        SizeSection(viewModel: viewModel)

        Section("Renk") {
            ColorSwatchRow(hex: viewModel.binding(\.tintColor, default: "#111111"), presets: tintPresets)
        }

        TapActionSection(action: viewModel.binding(\.action, default: ElementAction.none),
                         targets: viewModel.linkTargets)
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    let editor = EditorViewModel(catalog: catalog,
                                 symbolCatalog: try! SymbolCatalog.load(),
                                 screen: PrototypeScreen(name: "Önizleme"))
    editor.addElement(of: .symbol)
    return ElementPropertiesSheet(viewModel: editor)
}
