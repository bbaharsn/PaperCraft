//
//  TextFieldPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir metin kutusu seçiliyken alttan açılan "Özellikler" sayfasının içeriği.
struct TextFieldPropertiesSheet: View {
    let viewModel: EditorViewModel

    /// Kenarlık/ikon için hazır renkler (iOS grisi, mavi, vurgu, siyah, yeşil, kırmızı).
    private let accentPresets = ["#C7C7CC", "#007AFF", "#AC5135", "#111111", "#34C759", "#FF3B30"]
    /// Yazı için hazır renkler.
    private let textPresets = ["#111111", "#2B2118", "#8E8E93"]

    private var iconPosition: IconPosition {
        viewModel.selectedElement?.properties.iconPosition ?? .none
    }

    var body: some View {
        Section("İpucu Metni") {
            TextField("Örn. E-posta", text: viewModel.binding(\.placeholder, default: ""))
        }

        SizeSection(viewModel: viewModel)

        Section("Kenarlık") {
            OptionPicker(selection: viewModel.binding(\.border, default: .roundedBorder), title: \.title)
        }

        Section("Tür") {
            OptionPicker(selection: viewModel.binding(\.inputKind, default: .plain), title: \.title)
        }

        Section("Kenarlık Rengi") {
            ColorSwatchRow(hex: viewModel.binding(\.fillColor, default: "#C7C7CC"), presets: accentPresets)
        }

        Section("Yazı Rengi") {
            ColorSwatchRow(hex: viewModel.binding(\.contentColor, default: "#111111"), presets: textPresets)
        }

        Section("İkon") {
            OptionPicker(selection: viewModel.binding(\.iconPosition, default: .none), title: \.title)
            if iconPosition != .none {
                SymbolPickerRow(symbolName: viewModel.binding(\.symbolName, default: "magnifyingglass"),
                                symbols: viewModel.symbolCatalog.symbols)
            }
        }
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    let editor = EditorViewModel(catalog: catalog,
                                 symbolCatalog: try! SymbolCatalog.load(),
                                 screen: PrototypeScreen(name: "Önizleme"))
    editor.addElement(of: .textField)
    return ElementPropertiesSheet(viewModel: editor)
}
