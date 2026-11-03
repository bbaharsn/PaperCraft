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

    /// Kısa kenarın yarısı: daha fazlası görünümü değiştirmez.
    private var maxRadius: Double {
        guard let element = viewModel.selectedElement else { return 60 }
        let size = viewModel.pointRect(of: element).size
        return max(min(size.width, size.height) / 2, 1)
    }

    var body: some View {
        Section("Renk") {
            ColorSwatchRow(hex: viewModel.binding(\.fillColor, default: "#FFFFFF"), presets: fillPresets)
        }

        SizeSection(viewModel: viewModel)

        Section("Köşe") {
            Slider(value: radiusBinding, in: 0...maxRadius)
                .tint(Theme.ink)
        }

        Section("Kenarlık") {
            Stepper(value: viewModel.binding(\.borderWidth, default: 1), in: 0...8) {
                Text(borderWidthTitle)
            }
            if (properties.borderWidth ?? 1) > 0 {
                ColorSwatchRow(hex: viewModel.binding(\.borderColor, default: "#E5E5EA"), presets: borderPresets)
            }
        }

        Section("Gölge") {
            BoolPicker(isOn: viewModel.binding(\.hasShadow, default: false))
        }

        TapActionSection(action: viewModel.binding(\.action, default: ElementAction.none),
                         targets: viewModel.linkTargets)
    }

    /// Kaydırıcı en uçtayken kutu hap/daire olur; saklanan değer de o uca iner.
    private var radiusBinding: Binding<Double> {
        Binding(
            get: { min(properties.cornerRadius ?? 12, maxRadius) },
            set: { viewModel.binding(\.cornerRadius, default: 12).wrappedValue = $0.rounded() }
        )
    }

    private var borderWidthTitle: String {
        let width = Int(properties.borderWidth ?? 1)
        return width == 0 ? "Kenarlık yok" : "\(width) pt"
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
