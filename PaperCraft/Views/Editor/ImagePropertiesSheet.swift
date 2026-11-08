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
    /// Fotoğraf kenarlığı için hazır renkler (beyaz, siyah, vurgu, pembe, yeşil, mavi).
    private let borderPresets = ["#FFFFFF", "#111111", "#AC5135", "#E1306C", "#25D366", "#007AFF"]

    private var colorMode: ImageColorMode {
        viewModel.selectedElement?.properties.imageColorMode ?? .original
    }

    private var tintHex: String {
        viewModel.selectedElement?.properties.tintColor ?? "#111111"
    }

    private var frameShape: FrameShape {
        viewModel.selectedElement?.properties.frameShape ?? .rectangle
    }

    /// Yüklenen fotoğraf varken renk seçenekleri gizlenir; fotoğraf hep kendi renkleriyle çizilir.
    private var hasUploadedImage: Bool {
        viewModel.selectedElement?.properties.uploadedImageName != nil
    }

    var body: some View {
        UploadedImageSection(viewModel: viewModel)

        if hasUploadedImage {
            Section {
                OptionPicker(selection: viewModel.binding(\.frameShape, default: .rectangle), title: \.title)
                if frameShape == .rounded {
                    LabeledContent("Köşe") {
                        CornerRadiusSlider(viewModel: viewModel, defaultRadius: 12)
                    }
                }
                if frameShape != .circle {
                    OptionPicker(selection: viewModel.binding(\.contentMode, default: .fit), title: \.title)
                }
            } header: {
                Text("Şekil")
            } footer: {
                Text(frameShape == .circle
                     ? "Daire, fotoğrafı ortada tam daire olarak doldurur (profil fotoğrafı)."
                     : "Sığdır: fotoğrafın tamamı görünür. Doldur: çerçeveyi doldurur, taşan kısım kırpılır.")
            }

            BorderSection(viewModel: viewModel, defaultWidth: 0, defaultColor: "#FFFFFF", presets: borderPresets)
        } else {
            Section {
                OptionPicker(selection: viewModel.binding(\.imageColorMode, default: .original), title: \.title)
                if colorMode == .mono {
                    ColorSwatchRow(hex: viewModel.binding(\.tintColor, default: "#111111"), presets: tintPresets)
                }
            } header: {
                Text("Renk")
            }
        }

        TapActionSection(action: viewModel.binding(\.action, default: ElementAction.none),
                         targets: viewModel.linkTargets)

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
