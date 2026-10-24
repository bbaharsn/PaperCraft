//
//  ImageElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki bir görseli çizer: kütüphaneden seçilen görsel (renkli ya da tek renk)
/// veya henüz görsel seçilmemişse yer tutucu ikon.
struct ImageElementView: View {
    let properties: ElementProperties

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
        if let assetName {
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
