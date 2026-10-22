//
//  TabBarElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki alt menüyü sekmeleri, seçili sekmesi, renkleri ve köşeleriyle çizer.
/// Köşeli bar klasik alt menüdür: sekmeler üstteki 49 pt'lik kısımda durur, altta kalan boşluk
/// iPhone'un ana ekran çizgisinin yeri. Yuvarlak ya da hap bar iOS 26'daki yüzen alt menüdür:
/// sekmeler ortadadır, seçili sekmenin arkasında yumuşak bir vurgu ve barın altında gölge olur.
struct TabBarElementView: View {
    let properties: ElementProperties

    /// iOS'taki alt menünün sekme satırı yüksekliği.
    static let rowHeight: CGFloat = 49

    private var items: [TabItem] { properties.items ?? [] }
    private var selectedIndex: Int { properties.selectedIndex ?? 0 }
    private var showsLabels: Bool { properties.showsLabels ?? true }
    private var corner: TabBarCorner { properties.tabBarCorner ?? .square }
    private var shape: AnyShape { corner.buttonShape.outline }
    /// Köşeli olmayan bar yüzen alt menü gibi çizilir.
    private var isFloating: Bool { corner != .square }
    private var isTranslucent: Bool { properties.isTranslucent ?? false }

    private var backgroundColor: Color {
        properties.fillColor.flatMap(Color.init(hexString:)) ?? Color(white: 0.98)
    }

    private var selectedColor: Color {
        properties.tintColor.flatMap(Color.init(hexString:)) ?? .blue
    }

    private var unselectedColor: Color {
        properties.contentColor.flatMap(Color.init(hexString:)) ?? .gray
    }

    var body: some View {
        if isFloating {
            floatingBar
        } else {
            classicBar
        }
    }

    private var classicBar: some View {
        tabRow
            .frame(height: Self.rowHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(background)
            .overlay(alignment: .top) {
                if properties.showsDivider ?? true {
                    Rectangle()
                        .fill(.black.opacity(0.2))
                        .frame(height: 0.5)
                }
            }
    }

    /// İnce parlak kenarlı, hafif gölgeli bar.
    private var floatingBar: some View {
        tabRow
            .padding(4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                background
                    .overlay(shape.stroke(.white.opacity(0.7), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
            }
    }

    /// Düz arka plan tek renktir; saydamda arkadaki içerik bulanık görünür, renk üstüne yarı saydam biner.
    private var background: some View {
        ZStack {
            if isTranslucent {
                shape.fill(.ultraThinMaterial)
                shape.fill(backgroundColor.opacity(0.6))
            } else {
                shape.fill(backgroundColor)
            }
        }
    }

    private var tabRow: some View {
        HStack(spacing: 0) {
            // Aynı yazılı iki sekme olabilir, o yüzden sıra numarasıyla
            ForEach(items.indices, id: \.self) { index in
                tab(items[index], isSelected: index == selectedIndex)
            }
        }
    }

    /// Tek sekme: ikon ve altında yazı. Seçili sekmenin ikonu iOS'taki gibi dolu çizilir.
    private func tab(_ item: TabItem, isSelected: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: item.symbolName)
                .symbolVariant(isSelected ? .fill : .none)
                .font(.system(size: iconSize))
                .frame(height: isFloating ? 24 : 28)
            if showsLabels {
                Text(item.text)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .foregroundStyle(isSelected ? selectedColor : unselectedColor)
        .frame(maxWidth: .infinity, maxHeight: isFloating ? .infinity : nil)
        .background {
            if isFloating && isSelected {
                shape.fill(unselectedColor.opacity(0.18))
            }
        }
    }

    /// Yazılar kapalıyken ikon büyür; yüzen barda ikonlar biraz daha küçüktür.
    private var iconSize: CGFloat {
        if isFloating {
            showsLabels ? 19 : 22
        } else {
            showsLabels ? 22 : 26
        }
    }
}

#Preview {
    let items = [TabItem(text: "Home", symbolName: "house"),
                 TabItem(text: "Search", symbolName: "magnifyingglass"),
                 TabItem(text: "Profile", symbolName: "person")]
    let samples: [ElementProperties] = [
        ElementProperties(selectedIndex: 0, items: items, showsDivider: true),
        ElementProperties(selectedIndex: 1, items: items, tintColor: "#AC5135", fillColor: "#FBF7EE",
                          showsLabels: false, tabBarCorner: .rounded),
        ElementProperties(selectedIndex: 0, items: items, fillColor: "#F9F9F9", contentColor: "#3C3C43",
                          tabBarCorner: .capsule, isTranslucent: true),
    ]
    VStack(spacing: 20) {
        ForEach(samples.indices, id: \.self) { index in
            let isClassic = (samples[index].tabBarCorner ?? .square) == .square
            TabBarElementView(properties: samples[index])
                .frame(width: isClassic ? 393 : 361, height: isClassic ? 83 : 62)
        }
    }
    .padding()
    .background(Theme.paper)
}
