//
//  BoxPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir kutu seçiliyken alttan açılan "Özellikler" sayfasının içeriği.
struct BoxPropertiesSheet: View {
    let viewModel: EditorViewModel

    /// Dolgu için hazır renkler (beyaz, açık gri, vurgu, turuncu, kırmızı, siyah).
    private let fillPresets = ["#FFFFFF", "#F2F2F7", "#AC5135", "#F27A1A", "#FF3B30", "#111111"]
    /// Kenarlık için hazır renkler (açık gri, gri, vurgu, turuncu, mavi, siyah).
    private let borderPresets = ["#E5E5EA", "#8E8E93", "#AC5135", "#F27A1A", "#007AFF", "#111111"]

    private var properties: ElementProperties {
        viewModel.selectedElement?.properties ?? ElementProperties()
    }

    var body: some View {
        Section {
            BoolPicker(isOn: viewModel.binding(\.matchesPageBackground, default: false),
                       off: "Seçilen renk", on: "Sayfa arka planı")
            if !(properties.matchesPageBackground ?? false) {
                ColorSwatchRow(hex: viewModel.binding(\.fillColor, default: "#FFFFFF"), presets: fillPresets)
            }
        } header: {
            Text("Renk")
        } footer: {
            if properties.matchesPageBackground ?? false {
                Text("Kutu sayfanın arka planıyla aynı görünür; arka plan değişince kutu da değişir.")
            }
        }

        SizeSection(viewModel: viewModel)

        Section {
            OptionPicker(selection: viewModel.binding(\.frameShape, default: .rounded), title: \.title)
            if (properties.frameShape ?? .rounded) == .rounded {
                LabeledContent("Köşe") {
                    CornerRadiusSlider(viewModel: viewModel, defaultRadius: 12)
                }
            }
        } header: {
            Text("Şekil")
        } footer: {
            Text("Daire, kutu kare olmasa da ortada tam daire çizer. Tek parça yuvarlak ikon butonu için Buton'un Daire şeklini kullan.")
        }

        BorderSection(viewModel: viewModel, defaultWidth: 1, defaultColor: "#E5E5EA", presets: borderPresets)

        Section("Gölge") {
            BoolPicker(isOn: viewModel.binding(\.hasShadow, default: false))
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
    editor.addElement(of: .box)
    return ElementPropertiesSheet(viewModel: editor)
}
