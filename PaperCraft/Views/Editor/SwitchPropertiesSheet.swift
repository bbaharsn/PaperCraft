//
//  SwitchPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir anahtar seçiliyken alttan açılan "Özellikler" sayfasının içeriği.
struct SwitchPropertiesSheet: View {
    let viewModel: EditorViewModel

    /// Açıkken renk için hazır renkler (iOS yeşili, mavi, vurgu, turuncu, mor, kırmızı).
    private let tintPresets = ["#34C759", "#007AFF", "#AC5135", "#FF9500", "#AF52DE", "#FF3B30"]
    /// Etiket için hazır renkler.
    private let textPresets = ["#111111", "#2B2118", "#8E8E93"]

    var body: some View {
        Section("Durum") {
            Toggle("Açık", isOn: viewModel.binding(\.isOn, default: false))
        }

        Section {
            TextField("Örn. Bildirimler", text: viewModel.binding(\.text, default: ""))
            OptionPicker(selection: viewModel.binding(\.labelPosition, default: .leading), title: \.title)
        } header: {
            Text("Etiket")
        } footer: {
            Text("Boş bırakırsan sadece anahtar görünür.")
        }

        SizeSection(viewModel: viewModel)

        Section("Açıkken Renk") {
            ColorSwatchRow(hex: viewModel.binding(\.fillColor, default: "#34C759"), presets: tintPresets)
        }

        Section("Etiket Rengi") {
            ColorSwatchRow(hex: viewModel.binding(\.contentColor, default: "#111111"), presets: textPresets)
        }
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    let editor = EditorViewModel(catalog: catalog,
                                 symbolCatalog: try! SymbolCatalog.load(),
                                 screen: PrototypeScreen(name: "Önizleme"))
    editor.addElement(of: .switch)
    return ElementPropertiesSheet(viewModel: editor)
}
