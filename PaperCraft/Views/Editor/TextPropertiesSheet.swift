//
//  TextPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir metin seçiliyken alttan açılan "Özellikler" sayfasının içeriği.
struct TextPropertiesSheet: View {
    let viewModel: EditorViewModel

    /// Yazı için hazır renkler (siyah, koyu kahve, gri, vurgu, mavi, beyaz).
    private let textPresets = ["#111111", "#2B2118", "#8E8E93", "#AC5135", "#007AFF", "#FFFFFF"]

    var body: some View {
        Section("Metin") {
            TextField("Örn. Hoş geldin", text: viewModel.binding(\.text, default: ""), axis: .vertical)
        }

        Section("Yazı Stili") {
            OptionPicker(selection: viewModel.binding(\.textStyle, default: .body), title: \.title)
        }

        Section("Yazı Tipi") {
            FontPickerRow(fontName: viewModel.binding(\.fontName, default: FontFamilies.system))
        }

        Section("Kalınlık ve Eğim") {
            OptionPicker(selection: viewModel.binding(\.fontWeight, default: .regular), title: \.title)
            BoolPicker(isOn: viewModel.binding(\.isItalic, default: false), off: "Düz", on: "İtalik")
        }

        Section("Hizalama") {
            OptionPicker(selection: viewModel.binding(\.textAlignment, default: .leading), title: \.title)
        }

        SizeSection(viewModel: viewModel)

        Section("Yazı Rengi") {
            ColorSwatchRow(hex: viewModel.binding(\.contentColor, default: "#111111"), presets: textPresets)
        }
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    let editor = EditorViewModel(catalog: catalog,
                                 symbolCatalog: try! SymbolCatalog.load(),
                                 screen: PrototypeScreen(name: "Önizleme"))
    editor.addElement(of: .text)
    return ElementPropertiesSheet(viewModel: editor)
}
