//
//  SliderPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir kaydırıcı seçiliyken alttan açılan "Özellikler" sayfasının içeriği.
struct SliderPropertiesSheet: View {
    let viewModel: EditorViewModel

    /// Dolu kısım için hazır renkler (mavi, vurgu, yeşil, turuncu, mor, siyah).
    private let tintPresets = ["#007AFF", "#AC5135", "#34C759", "#FF9500", "#AF52DE", "#111111"]

    private var properties: ElementProperties {
        viewModel.selectedElement?.properties ?? ElementProperties()
    }

    var body: some View {
        Section("Değer") {
            Slider(value: viewModel.binding(\.value, default: 0.5), in: properties.sliderRange)
                .tint(Theme.ink)
            HStack {
                numberField("En az", value: rangeBinding(\.lowerBound))
                Text("…").foregroundStyle(.secondary)
                numberField("En çok", value: rangeBinding(\.upperBound))
            }
            Toggle("Değeri yazıyla göster", isOn: showsValueBinding)
        }

        SizeSection(viewModel: viewModel)

        Section("Renk") {
            ColorSwatchRow(hex: viewModel.binding(\.fillColor, default: "#007AFF"), presets: tintPresets)
        }

        Section {
            Toggle("İkonları göster", isOn: showsSideIconsBinding)
            if properties.showsSideIcons ?? false {
                symbolRow("Sol", symbolName: viewModel.binding(\.minSymbolName, default: "minus"))
                symbolRow("Sağ", symbolName: viewModel.binding(\.maxSymbolName, default: "plus"))
            }
        } header: {
            Text("Yan İkonlar")
        } footer: {
            Text("İkon ya da değer yazısı açılınca eleman o kadar genişler; çubuk kısalmaz.")
        }
    }

    // MARK: - Çerçeveyi de değiştiren ayarlar (ViewModel'deki metotlardan geçer)

    private var showsSideIconsBinding: Binding<Bool> {
        Binding(
            get: { properties.showsSideIcons ?? false },
            set: { viewModel.setSelectedSliderShowsSideIcons($0) }
        )
    }

    private var showsValueBinding: Binding<Bool> {
        Binding(
            get: { properties.showsValue ?? false },
            set: { viewModel.setSelectedSliderShowsValue($0) }
        )
    }

    /// Aralığın bir ucuna bağlanır; diğer uç olduğu gibi kalır.
    private func rangeBinding(_ bound: KeyPath<ClosedRange<Double>, Double>) -> Binding<Double> {
        Binding(
            get: { properties.sliderRange[keyPath: bound] },
            set: { newValue in
                let range = properties.sliderRange
                viewModel.setSelectedSliderRange(min: bound == \.lowerBound ? newValue : range.lowerBound,
                                                 max: bound == \.upperBound ? newValue : range.upperBound)
            }
        )
    }

    // MARK: - Parçalar

    /// Küçük başlıklı sayı kutusu. Değer "Bitti"ye (return) basınca uygulanır.
    private func numberField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number.precision(.fractionLength(0...2)))
                #if os(iOS)
                .keyboardType(.numbersAndPunctuation)
                #endif
                .submitLabel(.done)
        }
    }

    private func symbolRow(_ title: String, symbolName: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            SymbolPickerRow(symbolName: symbolName, symbols: viewModel.symbolCatalog.symbols)
        }
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    let editor = EditorViewModel(catalog: catalog,
                                 symbolCatalog: try! SymbolCatalog.load(),
                                 screen: PrototypeScreen(name: "Önizleme"))
    editor.addElement(of: .slider)
    return ElementPropertiesSheet(viewModel: editor)
}
