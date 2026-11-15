//
//  CatalogSidebar.swift
//  PaperCraft
//

import SwiftUI

/// Geniş ekranda (iPad) solda hep açık duran eleman kataloğu: üstte klasör sekmeleri, altta iki sütun kart.
/// iPhone'daki `CatalogPanel` ile aynı işi yapar; kart sağa (canvas'a doğru) çekilerek sürüklenir.
struct CatalogSidebar: View {
    let catalog: ComponentCatalog
    /// Bir karta basılınca hangi türün seçildiğini dışarıya haber verir.
    let onSelect: (ElementType) -> Void
    /// "arka plan" kartına basılınca çağrılır. Bu kart eleman eklemez, sayfanın ayarını açar.
    var onBackground: () -> Void = {}
    /// Bir kart sağa çekilip sürüklenirken parmağın ekrandaki yeri (global).
    var onDragChanged: (ElementType, CGPoint) -> Void = { _, _ in }
    /// Sürüklenen kart bırakılınca parmağın ekrandaki yeri (global).
    var onDragEnded: (ElementType, CGPoint) -> Void = { _, _ in }

    /// Panelin genişliği (point): iki kart ve aralarındaki boşluk.
    static let width: CGFloat = 264

    @State private var selectedCategory: String?
    @State private var cardGesture: CardGesture?

    private enum CardGesture: Equatable {
        case scrolling
        case dragging(ElementType)
    }

    /// Parmak bu kadar (point) gidince hareketin yönüne karar verilir.
    private static let decisionDistance: CGFloat = 8

    private let tilts: [Double] = [-2, 1.5, -1, 2]
    private let backgroundCategory = "Medya"
    private let columns = [GridItem(.fixed(104), spacing: 20), GridItem(.fixed(104))]

    private var currentCategory: String? {
        selectedCategory ?? catalog.categories.first
    }

    var body: some View {
        VStack(spacing: 0) {
            tabs
            content
        }
        .frame(width: Self.width)
    }

    private var tabs: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(catalog.categories, id: \.self) { category in
                let isSelected = category == currentCategory
                Button {
                    selectedCategory = category
                } label: {
                    Text(category)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        // Sekmeler satırı eşit paylaşır; dar panelde de hepsi görünür.
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? Theme.panel : Theme.tabInactive, in: tabShape)
                        .overlay(tabShape.stroke(Theme.ink, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 1)   // seçili sekmenin üst çizgisi kesilmesin
    }

    private var tabShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
    }

    private var content: some View {
        let cards = catalog.components(in: currentCategory ?? "")

        return ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(cards.enumerated()), id: \.element.type) { index, definition in
                    CatalogCard(definition: definition, tilt: tilts[index % tilts.count])
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect(definition.type) }
                        // Aşağı-yukarı kaydırma kartları kaydırır; sağa çekmek kartı sürükler.
                        .simultaneousGesture(dragGesture(for: definition.type))
                        .accessibilityAddTraits(.isButton)
                }

                if currentCategory == backgroundCategory {
                    backgroundCard(tilt: tilts[cards.count % tilts.count])
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: .infinity)
        .background(Theme.panel)
        .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: Theme.cornerRadius, topTrailingRadius: Theme.cornerRadius))
        .overlay(
            UnevenRoundedRectangle(bottomTrailingRadius: Theme.cornerRadius, topTrailingRadius: Theme.cornerRadius)
                .stroke(Theme.ink, lineWidth: 1)
        )
    }

    /// İlk birkaç point'te yön belli olur: sağa ağırlıklıysa sürükleme başlar, değilse
    /// bu hareket boyunca kartlar sadece kayar.
    private func dragGesture(for type: ElementType) -> some Gesture {
        DragGesture(minimumDistance: Self.decisionDistance, coordinateSpace: .global)
            .onChanged { value in
                if cardGesture == nil {
                    let move = value.translation
                    let isSideways = move.width > 0 && abs(move.width) > abs(move.height)
                    cardGesture = isSideways ? .dragging(type) : .scrolling
                }
                if cardGesture == .dragging(type) {
                    onDragChanged(type, value.location)
                }
            }
            .onEnded { value in
                defer { cardGesture = nil }
                if cardGesture == .dragging(type) {
                    onDragEnded(type, value.location)
                }
            }
    }

    private func backgroundCard(tilt: Double) -> some View {
        Button(action: onBackground) {
            CatalogCardFrame(title: "arka plan", tilt: tilt) {
                Circle()
                    .fill(LinearGradient(colors: [Theme.paper, Theme.accent],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Circle().stroke(Theme.ink, lineWidth: 1))
                    .frame(width: 40, height: 40)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        CatalogSidebar(catalog: try! ComponentCatalog.load(), onSelect: { _ in })
        Spacer()
    }
    .background(Theme.background)
}
