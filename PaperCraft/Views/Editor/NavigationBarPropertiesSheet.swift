//
//  NavigationBarPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir üst bar seçiliyken alttan açılan "Özellikler" sayfasının içeriği.
/// Boyut bölümü yok: genişlik hep ekran kadar, yükseklik başlık türünden gelir.
struct NavigationBarPropertiesSheet: View {
    let viewModel: EditorViewModel

    /// Arka plan için hazır renkler (iOS açık gri, beyaz, kâğıt, siyah, mavi, vurgu).
    private let backgroundPresets = ["#F9F9F9", "#FFFFFF", "#FBF7EE", "#111111", "#007AFF", "#AC5135"]
    /// Başlık için hazır renkler.
    private let titlePresets = ["#111111", "#2B2118", "#FFFFFF"]
    /// Geri ve sağ buton için hazır renkler.
    private let tintPresets = ["#007AFF", "#AC5135", "#111111", "#FFFFFF", "#34C759"]

    private var properties: ElementProperties? {
        viewModel.selectedElement?.properties
    }

    var body: some View {
        Section("Başlık") {
            TextField("Örn. Ayarlar", text: viewModel.binding(\.text, default: ""))
            OptionPicker(selection: titleModeBinding, title: \.title)
        }

        Section {
            OptionPicker(selection: viewModel.binding(\.textAlignment, default: .center), title: \.title)
            OptionPicker(selection: viewModel.binding(\.verticalAlignment, default: .center), title: \.title)
        } header: {
            Text("Başlık Konumu")
        } footer: {
            Text("Dikey konum, barı aşağı doğru uzattığında fark eder.")
        }

        Section("Yazı Tipi") {
            FontPickerRow(fontName: viewModel.binding(\.fontName, default: FontFamilies.system))
        }

        Section {
            BoolPicker(isOn: viewModel.binding(\.showsBackButton, default: false))
            if properties?.showsBackButton ?? false {
                TextField("Örn. Geri", text: viewModel.binding(\.backTitle, default: ""))
            }
        } header: {
            Text("Geri Butonu")
        } footer: {
            Text("Yazıyı boş bırakırsan sadece ok görünür.")
        }

        Section("Sağ Buton") {
            OptionPicker(selection: viewModel.binding(\.trailingItem, default: .none), title: \.title)
            switch properties?.trailingItem ?? .none {
            case .none:
                EmptyView()
            case .icon:
                SymbolPickerRow(symbolName: viewModel.binding(\.symbolName, default: "plus"),
                                symbols: viewModel.symbolCatalog.symbols)
            case .text:
                TextField("Örn. Düzenle", text: viewModel.binding(\.trailingText, default: ""))
            }
        }

        Section("Arka Plan") {
            ColorSwatchRow(hex: viewModel.binding(\.fillColor, default: "#F9F9F9"), presets: backgroundPresets)
        }

        Section("Başlık Rengi") {
            ColorSwatchRow(hex: viewModel.binding(\.contentColor, default: "#111111"), presets: titlePresets)
        }

        Section("Buton Rengi") {
            ColorSwatchRow(hex: viewModel.binding(\.tintColor, default: "#007AFF"), presets: tintPresets)
        }

        Section("Alt Çizgi") {
            BoolPicker(isOn: viewModel.binding(\.showsDivider, default: true))
        }
    }

    /// Başlık türü ayrı ele alınır: büyük başlıkta barın da uzaması gerekir.
    private var titleModeBinding: Binding<NavigationTitleMode> {
        Binding(
            get: { properties?.titleDisplayMode ?? .inline },
            set: { viewModel.setSelectedNavigationTitleMode($0) }
        )
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    let editor = EditorViewModel(catalog: catalog,
                                 symbolCatalog: try! SymbolCatalog.load(),
                                 screen: PrototypeScreen(name: "Önizleme"))
    editor.addElement(of: .navigationBar)
    return ElementPropertiesSheet(viewModel: editor)
}
