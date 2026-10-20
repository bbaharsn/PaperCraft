//
//  ButtonPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir buton seçiliyken alttan açılan "Özellikler" sayfası.
/// Her değişiklik anında canvas'a yansır; ayrıca kaydetmeye gerek yok.
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
        NavigationStack {
            Form {
                Section("Metin") {
                    TextField("Buton yazısı", text: binding(\.text, default: ""))
                }

                Section("Şekil") {
                    segmented(binding(\.shape, default: .rounded), title: \.title)
                    segmented(binding(\.fill, default: .filled), title: \.title)
                }

                Section("Renk") {
                    ColorSwatchRow(hex: binding(\.fillColor, default: "#007AFF"), presets: fillPresets)
                }

                // Yazı rengi sadece dolu butonda ayrı; diğerlerinde ana rengi kullanır.
                if fill == .filled {
                    Section("Yazı Rengi") {
                        ColorSwatchRow(hex: binding(\.contentColor, default: "#FFFFFF"), presets: contentPresets)
                    }
                }

                Section("İkon") {
                    segmented(binding(\.iconPosition, default: .none), title: \.title)
                    if iconPosition != .none {
                        SymbolPickerRow(symbolName: binding(\.symbolName, default: "arrow.right"),
                                        symbols: viewModel.symbolCatalog.symbols)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.panel)
            .navigationTitle("Buton")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bitti") { viewModel.select(nil) }
                }
            }
        }
    }

    /// Seçili elemanın bir özelliğine bağlanan `Binding`.
    /// Özellik boşsa (`nil`) `default` değeri gösterilir; değiştirince modele yazılır.
    private func binding<Value>(_ keyPath: WritableKeyPath<ElementProperties, Value?>,
                                default defaultValue: Value) -> Binding<Value> {
        Binding(
            get: { viewModel.selectedElement?.properties[keyPath: keyPath] ?? defaultValue },
            set: { newValue in viewModel.updateSelectedProperties { $0[keyPath: keyPath] = newValue } }
        )
    }

    /// Bir enum'un tüm seçeneklerini yan yana bölmeli seçici olarak gösterir.
    private func segmented<Option: CaseIterable & Hashable>(
        _ selection: Binding<Option>,
        title: KeyPath<Option, String>
    ) -> some View where Option.AllCases: RandomAccessCollection {
        Picker("", selection: selection) {
            ForEach(Array(Option.allCases), id: \.self) { option in
                Text(option[keyPath: title]).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    let editor = EditorViewModel(catalog: catalog,
                                 symbolCatalog: try! SymbolCatalog.load(),
                                 screen: PrototypeScreen(name: "Önizleme"))
    editor.addElement(of: .button)
    return ButtonPropertiesSheet(viewModel: editor)
}
