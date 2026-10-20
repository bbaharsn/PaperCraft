//
//  ButtonPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir buton seçiliyken alttan açılan "Özellikler" sayfasının içeriği
/// (çerçevesi `ElementPropertiesSheet`'te). Her değişiklik anında canvas'a yansır.
struct ButtonPropertiesSheet: View {
    let viewModel: EditorViewModel

    /// Hazır ana renkler (mavi, vurgu, siyah, yeşil, turuncu, kırmızı, mor).
    private let fillPresets = ["#007AFF", "#AC5135", "#111111", "#34C759", "#FF9500", "#FF3B30", "#5856D6"]
    /// Dolu butondaki yazı için hazır renkler.
    private let contentPresets = ["#FFFFFF", "#111111", "#FBF7EE"]

    private var fill: ButtonFill {
        viewModel.selectedElement?.properties.fill ?? .filled
    }

    private var iconPosition: IconPosition {
        viewModel.selectedElement?.properties.iconPosition ?? .none
    }

    var body: some View {
        Section("Metin") {
            TextField("Buton yazısı", text: viewModel.binding(\.text, default: ""))
        }

        SizeSection(viewModel: viewModel)

        Section("Şekil") {
            OptionPicker(selection: shapeBinding, title: \.title)
            OptionPicker(selection: viewModel.binding(\.fill, default: .filled), title: \.title)
        }

        Section("Renk") {
            ColorSwatchRow(hex: viewModel.binding(\.fillColor, default: "#007AFF"), presets: fillPresets)
        }

        // Yazı rengi sadece dolu butonda ayrı; diğerlerinde ana rengi kullanır.
        if fill == .filled {
            Section("Yazı Rengi") {
                ColorSwatchRow(hex: viewModel.binding(\.contentColor, default: "#FFFFFF"),
                               presets: contentPresets)
            }
        }

        Section("İkon") {
            OptionPicker(selection: viewModel.binding(\.iconPosition, default: .none), title: \.title)
            if iconPosition != .none {
                SymbolPickerRow(symbolName: viewModel.binding(\.symbolName, default: "arrow.right"),
                                symbols: viewModel.symbolCatalog.symbols)
            }
        }
    }

    /// Şekil ayrı ele alınır: daireye geçince çerçevenin de kareye dönmesi gerekir.
    private var shapeBinding: Binding<ButtonShape> {
        Binding(
            get: { viewModel.selectedElement?.properties.shape ?? .rounded },
            set: { viewModel.setSelectedButtonShape($0) }
        )
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    let editor = EditorViewModel(catalog: catalog,
                                 symbolCatalog: try! SymbolCatalog.load(),
                                 screen: PrototypeScreen(name: "Önizleme"))
    editor.addElement(of: .button)
    return ElementPropertiesSheet(viewModel: editor)
}
