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

    /// Yüklenen fotoğraf varken renk seçenekleri gizlenir; fotoğraf hep kendi renkleriyle çizilir.
    private var hasUploadedImage: Bool {
        viewModel.selectedElement?.properties.uploadedImageName != nil
    }

    var body: some View {
        UploadedImageSection(viewModel: viewModel)

        if !hasUploadedImage {
            Section {
                OptionPicker(selection: viewModel.binding(\.imageColorMode, default: .original), title: \.title)
                if colorMode == .mono {
                    ColorSwatchRow(hex: viewModel.binding(\.tintColor, default: "#111111"), presets: tintPresets)
                }
            } header: {
                Text("Renk")
            }
        }

        SizeSection(viewModel: viewModel)

        Section {
            HStack {
                TextField("Açı", value: rotationBinding, format: .number.precision(.fractionLength(0)))
                    #if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    #endif
                Text("°").foregroundStyle(.secondary)
                Spacer()
                Button("Düz yap") { rotationBinding.wrappedValue = 0 }
                    .buttonStyle(.borderless)
            }
        } header: {
            Text("Döndürme")
        } footer: {
            Text("Canvas'ta sağ üstteki yuvarlak tutamaçtan da döndürebilirsin.")
        }

        Section("Hazır Görseller: Yiyecek & İçecek") {
            ImagePickerGrid(imageName: libraryImageBinding,
                            images: viewModel.imageLibrary.images,
                            colorMode: colorMode,
                            tintColor: Color(hexString: tintHex) ?? .primary)
        }
    }

    /// Yazılan açı 0..<360 aralığına çekilir (-90 → 270).
    private var rotationBinding: Binding<Double> {
        Binding(
            get: { viewModel.selectedElement?.properties.rotation ?? 0 },
            set: { degrees in
                guard let id = viewModel.selectedElementID else { return }
                viewModel.setRotation(id, degrees: degrees)
            }
        )
    }

    /// Kütüphaneden görsel seçilince yüklenen fotoğraf kaldırılır.
    private var libraryImageBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedElement?.properties.imageName ?? "" },
            set: { viewModel.setSelectedLibraryImage($0) }
        )
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
