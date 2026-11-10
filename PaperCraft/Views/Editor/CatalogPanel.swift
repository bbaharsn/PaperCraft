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
    /// "arka plan" kartına basılınca çağrılır. Bu kart eleman eklemez, sayfanın ayarını açar.
    var onBackground: () -> Void = {}
    /// Bir kart yukarı çekilip sürüklenirken parmağın ekrandaki yeri (global).
    var onDragChanged: (ElementType, CGPoint) -> Void = { _, _ in }
    /// Sürüklenen kart bırakılınca parmağın ekrandaki yeri (global).
    var onDragEnded: (ElementType, CGPoint) -> Void = { _, _ in }

    /// Seçili sekme. Henüz seçilmediyse ilk kategori gösterilir.
    @State private var selectedCategory: String?
    /// Bu parmak hareketi ne oldu: kartlar yana mı kaydırılıyor, bir kart mı sürükleniyor?
    @State private var cardGesture: CardGesture?

    private enum CardGesture: Equatable {
        case scrolling
        case dragging(ElementType)
    }

    /// Parmak bu kadar (point) gidince hareketin yönüne karar verilir.
    private static let decisionDistance: CGFloat = 8

    /// Kartların sırayla alacağı eğim açıları (derece).
    private let tilts: [Double] = [-2, 1.5, -1, 2]
    /// "arka plan" kartının durduğu sekme.
    private let backgroundCategory = "Medya"

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
                    // Button değil: Button parmak kayıp bırakılınca da basılmış sayılıyor,
                    // dokunuş hareketi ise parmak kayınca iptal olur.
                    CatalogCard(definition: definition, tilt: tilts[index % tilts.count])
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect(definition.type) }
                        // Yana kaydırma kartları kaydırır; yukarı çekmek kartı sürükler.
                        .simultaneousGesture(dragGesture(for: definition.type))
                        .accessibilityAddTraits(.isButton)
                }

                if currentCategory == backgroundCategory {
                    backgroundCard(tilt: tilts[cards.count % tilts.count])
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

    /// İlk birkaç point'te yön belli olur: yukarı ağırlıklıysa sürükleme başlar, değilse
    /// bu hareket boyunca kartlar sadece kayar.
    private func dragGesture(for type: ElementType) -> some Gesture {
        DragGesture(minimumDistance: Self.decisionDistance, coordinateSpace: .global)
            .onChanged { value in
                if cardGesture == nil {
                    let move = value.translation
                    let isUpward = move.height < 0 && abs(move.height) > abs(move.width)
                    cardGesture = isUpward ? .dragging(type) : .scrolling
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

    /// Katalog JSON'ında değil, çünkü tuvale eleman eklemiyor.
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
    VStack {
        Spacer()
        CatalogPanel(catalog: try! ComponentCatalog.load(), onSelect: { _ in })
    }
    .background(Theme.background)
}
