//
//  ImageElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki bir görseli çizer: yüklenen fotoğraf (arka planlı ya da arka plansız),
/// kütüphaneden seçilen görsel (renkli ya da tek renk) veya henüz görsel yoksa yer tutucu ikon.
struct ImageElementView: View {
    let properties: ElementProperties
    var store = UploadedImageStore.shared

    /// Yüklenen fotoğraf; yoksa ya da dosyası bulunamazsa `nil`.
    private var uploadedImage: CGImage? {
        guard let name = properties.uploadedImageName else { return nil }
        if properties.removesBackground == true,
           let cutout = store.image(named: UploadedImageStore.backgroundRemovedName(for: name)) {
            return cutout
        }
        return store.image(named: name)
    }

    private var colorMode: ImageColorMode { properties.imageColorMode ?? .original }

    /// Tek renk halinin rengi
    private var tintColor: Color {
        properties.tintColor.flatMap(Color.init(hexString:)) ?? .primary
    }

    /// Assets'teki adı; görsel seçilmemişse ya da Assets'te yoksa (ör. AI uydurduysa) `nil`.
    private var assetName: String? {
        guard let name = properties.imageName, !name.isEmpty else { return nil }
        let asset = colorMode == .mono ? name + "_mono" : name
        return Self.assetExists(asset) ? asset : nil
    }

    var body: some View {
        if let uploadedImage {
            photo(uploadedImage)
        } else if let assetName {
            Image(assetName)
                .resizable()
                .renderingMode(colorMode == .mono ? .template : .original)
                .scaledToFit()
                .foregroundStyle(tintColor)
        } else {
            Image(systemName: properties.symbolName ?? "photo")
                .resizable()
                .scaledToFit()
                .foregroundStyle(colorMode == .mono ? tintColor : .primary)
        }
    }

    private var frameShape: FrameShape { properties.frameShape ?? .rectangle }

    /// Daire her zaman doldurur: içi boş kalan bir daire profil fotoğrafına benzemez.
    private var contentMode: ImageContentMode {
        frameShape == .circle ? .fill : (properties.contentMode ?? .fit)
    }

    /// Yüklenen fotoğraf: çerçeveye sığar ya da çerçeveyi doldurur, sonra şekline göre kırpılır.
    @ViewBuilder
    private func photo(_ image: CGImage) -> some View {
        let shape = FrameOutline(shape: frameShape, cornerRadius: properties.cornerRadius ?? 12)
        switch contentMode {
        case .fit:
            // Şekil, fotoğrafın görünen kısmına uygulanır (çerçevedeki boşluğa değil).
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFit()
                .clipShape(shape)
                .overlay { border(shape) }
        case .fill:
            // Çerçeveyi dolduran boş bir yüzeyin üstüne taşan fotoğraf konur, sonra kırpılır.
            // Dairede kırpma ortadaki karededir; fotoğraf o kareyi de doldurur.
            Color.clear
                .overlay {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(shape)
                .overlay { border(shape) }
        }
    }

    /// Fotoğrafın şeklini izleyen kenarlık; fotoğrafın içine doğru çizilir, dışarı taşmaz.
    @ViewBuilder
    private func border(_ shape: FrameOutline) -> some View {
        let width = max(properties.borderWidth ?? 0, 0)
        if width > 0 {
            shape.strokeBorder(properties.borderColor.flatMap(Color.init(hexString:)) ?? .white, lineWidth: width)
        }
    }

    /// `Image(_:)` olmayan bir adda hata vermez, boş çizer; o yüzden önce kontrol ediyoruz.
    private static func assetExists(_ name: String) -> Bool {
        #if canImport(UIKit)
        UIImage(named: name) != nil
        #else
        NSImage(named: name) != nil
        #endif
    }
}

#Preview {
    let samples: [ElementProperties] = [
        ElementProperties(symbolName: "photo"),
        ElementProperties(imageName: "hot_beverage", imageColorMode: .original),
        ElementProperties(tintColor: "#AC5135", imageName: "hot_beverage", imageColorMode: .mono),
        ElementProperties(imageName: "uydurma_ad"),
    ]
    HStack(spacing: 16) {
        ForEach(samples.indices, id: \.self) { index in
            ImageElementView(properties: samples[index])
                .frame(width: 80, height: 80)
        }
    }
    .padding()
    .background(Theme.paper)
}
