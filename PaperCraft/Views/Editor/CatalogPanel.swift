//
//  CatalogPanel.swift
//  PaperCraft
//

import SwiftUI

/// Ekranın altında açılan eleman kataloğu: üstte klasör sekmeleri, altta kartlar.
struct CatalogPanel: View {
    let catalog: ComponentCatalog
    /// Bir karta basılınca hangi türün seçildiğini dışarıya haber verir.
    let onSelect: (ElementType) -> Void

    /// Seçili sekme. Henüz seçilmediyse ilk kategori gösterilir.
    @State private var selectedCategory: String?

    /// Kartların sırayla alacağı eğim açıları (derece).
    private let tilts: [Double] = [-2, 1.5, -1, 2]

    private var categories: [String] {
        catalog.categories
    }

    private var currentCategory: String? {
        selectedCategory ?? categories.first
    }

    var body: some View {
        VStack(spacing: 0) {
            tabs
            content
        }
    }

    private var tabs: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(categories, id: \.self) { category in
                let isSelected = category == currentCategory
                Button {
                    selectedCategory = category
                } label: {
                    Text(category)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? Theme.panel : Theme.tabInactive, in: tabShape)
                        .overlay(tabShape.stroke(Theme.ink, lineWidth: 1))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
    }

    /// Sadece üst köşeleri yuvarlak bir klasör sekmesi şekli.
    private var tabShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
    }

    private var content: some View {
        let cards = catalog.components(in: currentCategory ?? "")

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(cards.enumerated()), id: \.element.type) { index, definition in
                    Button {
                        onSelect(definition.type)
                    } label: {
                        CatalogCard(definition: definition, tilt: tilts[index % tilts.count])
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity)
            .background(Theme.panel.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.ink).frame(height: 1)
            }
    }
}

#Preview {
    VStack {
        Spacer()
        CatalogPanel(catalog: try! ComponentCatalog.load(), onSelect: { _ in })
    }
    .background(Theme.background)
}
