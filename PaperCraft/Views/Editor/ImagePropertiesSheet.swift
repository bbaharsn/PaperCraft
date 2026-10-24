//
//  ImagePropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Bir görsel seçiliyken alttan açılan "Özellikler" sayfasının içeriği.
struct ImagePropertiesSheet: View {
    let viewModel: EditorViewModel

    /// Tek renk için hazır renkler (siyah, koyu kahve, vurgu, mavi, yeşil, beyaz).
    private let tintPresets = ["#111111", "#2B2118", "#AC5135", "#007AFF", "#34C759", "#FFFFFF"]

    private var colorMode: ImageColorMode {
        viewModel.selectedElement?.properties.imageColorMode ?? .original
    }

    private var tintHex: String {
        viewModel.selectedElement?.properties.tintColor ?? "#111111"
    }

    var body: some View {
        Section {
            OptionPicker(selection: viewModel.binding(\.imageColorMode, default: .original), title: \.title)
            if colorMode == .mono {
                ColorSwatchRow(hex: viewModel.binding(\.tintColor, default: "#111111"), presets: tintPresets)
            }
        } header: {
            Text("Renk")
        }

        SizeSection(viewModel: viewModel)

        Section("Yiyecek & İçecek") {
            ImagePickerGrid(imageName: viewModel.binding(\.imageName, default: ""),
                            images: viewModel.imageLibrary.images,
                            colorMode: colorMode,
                            tintColor: Color(hexString: tintHex) ?? .primary)
        }
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    let editor = EditorViewModel(catalog: catalog,
                                 symbolCatalog: try! SymbolCatalog.load(),
                                 imageLibrary: try! ImageLibrary.load(),
                                 screen: PrototypeScreen(name: "Önizleme"))
    editor.addElement(of: .image)
    return ElementPropertiesSheet(viewModel: editor)
}
