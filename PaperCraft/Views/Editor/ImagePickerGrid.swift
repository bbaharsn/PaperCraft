//
//  ImagePickerGrid.swift
//  PaperCraft
//

import SwiftUI

/// Görsel kütüphanesini küçük kareler halinde gösterir; dokunulan görsel seçilir.
/// Kareler seçili renk moduna göre (renkli ya da tek renk) çizilir.
struct ImagePickerGrid: View {
    @Binding var imageName: String
    let images: [ImageLibraryEntry]
    let colorMode: ImageColorMode
    let tintColor: Color

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(images, id: \.name) { image in
                let isSelected = image.name == imageName
                Button {
                    imageName = image.name
                } label: {
                    thumbnail(image)
                        .padding(8)
                        .frame(width: 52, height: 52)
                        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.ink, lineWidth: isSelected ? 2 : 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(image.title)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func thumbnail(_ image: ImageLibraryEntry) -> some View {
        if colorMode == .mono {
            Image(image.monoName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(tintColor)
        } else {
            Image(image.name)
                .resizable()
                .scaledToFit()
        }
    }
}

#Preview {
    @Previewable @State var imageName = "hot_beverage"
    Form {
        ImagePickerGrid(imageName: $imageName, images: try! ImageLibrary.load().images,
                        colorMode: .original, tintColor: .black)
    }
}
