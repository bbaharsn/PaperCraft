//
//  ButtonPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir buton seçiliyken alttan açılan "Özellikler" sayfası.
/// Her değişiklik anında canvas'a yansır; ayrıca kaydetmeye gerek yok.
struct ButtonPropertiesSheet: View {
    let viewModel: EditorViewModel

    /// "Bitti" sadece sayfayı kapatır; buton seçili kalır.
    @Environment(\.dismiss) private var dismiss

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

                Section("Boyut") {
                    HStack {
                        sizeField("Genişlik", value: sizeBinding(\.width))
                        Text("×").foregroundStyle(.secondary)
                        sizeField("Yükseklik", value: sizeBinding(\.height))
                    }
                }

                Section("Şekil") {
                    segmented(shapeBinding, title: \.title)
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
                    Button("Bitti") { dismiss() }
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

    /// Şekil ayrı ele alınır: daireye geçince çerçevenin de kareye dönmesi gerekir.
    private var shapeBinding: Binding<ButtonShape> {
        Binding(
            get: { viewModel.selectedElement?.properties.shape ?? .rounded },
            set: { viewModel.setSelectedButtonShape($0) }
        )
    }

    /// Seçili elemanın genişliğine ya da yüksekliğine (point) bağlanan `Binding`.
    private func sizeBinding(_ keyPath: KeyPath<CGSize, CGFloat>) -> Binding<Double> {
        Binding(
            get: {
                guard let element = viewModel.selectedElement else { return 0 }
                return Double(viewModel.pointRect(of: element).size[keyPath: keyPath].rounded())
            },
            set: { newValue in
                guard let element = viewModel.selectedElement else { return }
                var size = viewModel.pointRect(of: element).size
                if keyPath == \CGSize.width { size.width = newValue } else { size.height = newValue }
                viewModel.setSelectedSize(width: size.width, height: size.height)
            }
        )
    }

    /// Küçük başlıklı sayı kutusu. Değer "Bitti"ye (return) basınca uygulanır.
    private func sizeField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number.precision(.fractionLength(0)))
                #if os(iOS)
                .keyboardType(.numbersAndPunctuation)
                #endif
                .submitLabel(.done)
        }
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
