//
//  TabBarPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir alt menü seçiliyken alttan açılan "Özellikler" sayfasının içeriği.
struct TabBarPropertiesSheet: View {
    let viewModel: EditorViewModel

    /// Arka plan için hazır renkler (iOS açık gri, beyaz, kâğıt, siyah, mavi, vurgu).
    private let backgroundPresets = ["#F9F9F9", "#FFFFFF", "#FBF7EE", "#111111", "#007AFF", "#AC5135"]
    /// Seçili sekme için hazır renkler.
    private let selectedPresets = ["#007AFF", "#AC5135", "#111111", "#FFFFFF", "#34C759"]
    /// Diğer sekmeler için hazır renkler (iOS gri, koyu gri, açık gri).
    private let unselectedPresets = ["#8E8E93", "#3C3C43", "#C7C7CC", "#FFFFFF"]

    private var properties: ElementProperties? {
        viewModel.selectedElement?.properties
    }

    private var items: [TabItem] {
        properties?.items ?? []
    }

    var body: some View {
        Section {
            OptionPicker(selection: viewModel.binding(\.tabBarCorner, default: .square), title: \.title)
        } header: {
            Text("Köşeler")
        } footer: {
            Text("Yuvarlak ve hap köşeli bar, iOS 26'daki yüzen alt menü gibi görünür.")
        }

        SizeSection(viewModel: viewModel)

        Section {
            ForEach(items.indices, id: \.self) { index in
                NavigationLink {
                    TabItemPropertiesView(viewModel: viewModel, index: index)
                } label: {
                    Label(items[index].text, systemImage: items[index].symbolName)
                }
            }
            .onDelete { offsets in
                // Sondan silinir ki öndeki silme arkadakilerin sırasını kaydırmasın
                offsets.sorted(by: >).forEach { viewModel.removeSelectedTab(at: $0) }
            }

            Button("Sekme Ekle", systemImage: "plus") {
                viewModel.addSelectedTab()
            }
            .disabled(items.count >= TabItem.allowedCount.upperBound)
        } header: {
            Text("Sekmeler")
        } footer: {
            Text("Düzenlemek için sekmeye dokun, silmek için sola kaydır. En az 2, en çok 5 sekme.")
        }

        Section("Seçili Sekme") {
            Picker("", selection: viewModel.binding(\.selectedIndex, default: 0)) {
                ForEach(items.indices, id: \.self) { index in
                    Text(items[index].text).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }

        Section("Sekme Yazıları") {
            BoolPicker(isOn: viewModel.binding(\.showsLabels, default: true))
        }

        Section {
            ColorSwatchRow(hex: viewModel.binding(\.fillColor, default: "#F9F9F9"), presets: backgroundPresets)
            BoolPicker(isOn: viewModel.binding(\.isTranslucent, default: false), off: "Düz", on: "Saydam")
        } header: {
            Text("Arka Plan")
        } footer: {
            Text("Saydam arka planda barın arkasındaki içerik bulanık görünür.")
        }

        Section("Seçili Sekme Rengi") {
            ColorSwatchRow(hex: viewModel.binding(\.tintColor, default: "#007AFF"), presets: selectedPresets)
        }

        Section("Diğer Sekmelerin Rengi") {
            ColorSwatchRow(hex: viewModel.binding(\.contentColor, default: "#8E8E93"), presets: unselectedPresets)
        }

        // Yüzen (yuvarlak/hap) barın çizgisi yok; kenarı zaten ince bir çizgiyle çiziliyor
        if (properties?.tabBarCorner ?? .square) == .square {
            Section("Üst Çizgi") {
                BoolPicker(isOn: viewModel.binding(\.showsDivider, default: true))
            }
        }
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    let editor = EditorViewModel(catalog: catalog,
                                 symbolCatalog: try! SymbolCatalog.load(),
                                 screen: PrototypeScreen(name: "Önizleme"))
    editor.addElement(of: .tabBar)
    return ElementPropertiesSheet(viewModel: editor)
}
