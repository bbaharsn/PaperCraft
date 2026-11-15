//
//  EditorView+Wide.swift
//  PaperCraft
//

import SwiftUI

/// iPad düzeni: üstte aynı üst bar; altında solda katalog, ortada canvas, sağda Özellikler paneli.
/// iPhone'daki alttan açılan katalog ve sayfaların yerine sabit paneller kullanılır; içerikleri aynıdır.
extension EditorView {

    /// Sağdaki Özellikler panelinin genişliği (point).
    static let inspectorWidth: CGFloat = 340
    /// Bundan dar alanda (ör. dikey iPad) iki panel aynı anda açılmaz; Özellikler açılınca katalog gizlenir.
    static let roomyWidth: CGFloat = 1000

    /// Sağ panel açık mı: arka plan ayarları ya da seçili elemanın Özellikleri.
    var isInspectorOpen: Bool {
        isEditingBackground || isShowingProperties.wrappedValue
    }

    var wideLayout: some View {
        VStack(spacing: 0) {
            topBar
                .zIndex(1)
            GeometryReader { geometry in
                let isRoomy = geometry.size.width >= Self.roomyWidth
                HStack(spacing: 0) {
                    if isSidebarOpen && (isRoomy || !isInspectorOpen) {
                        sidebar
                            .padding(.bottom, 16)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    canvas(bottomInset: 0, onBackgroundTap: {})
                        .padding()
                        .frame(maxWidth: .infinity)
                    if isInspectorOpen {
                        inspector
                            .padding(.bottom, 16)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .animation(.snappy, value: isInspectorOpen)
                .animation(.snappy, value: isSidebarOpen)
            }
        }
    }

    private var sidebar: some View {
        CatalogSidebar(
            catalog: viewModel.catalog,
            onSelect: { type in add(type, at: nil) },
            onBackground: openBackground,
            onDragChanged: catalogDragChanged,
            onDragEnded: catalogDragEnded
        )
        .sheet(isPresented: $isPickingSymbol, onDismiss: { symbolDropPoint = nil }) {
            SymbolCatalogSheet(symbols: viewModel.symbolCatalog.symbols) { name in
                viewModel.addSymbol(named: name, centeredAt: symbolDropPoint)
            }
        }
    }

    /// Özellikler paneli: iPhone'daki sayfaların aynısı, sağ kenara yapışık.
    /// "Bitti" sadece paneli kapatır; eleman seçili kalır, başka eleman seçilince yeniden açılır.
    @ViewBuilder
    private var inspector: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: Theme.cornerRadius,
                                           bottomLeadingRadius: Theme.cornerRadius)
        Group {
            if isEditingBackground {
                BackgroundPropertiesSheet(viewModel: viewModel, onDone: { isEditingBackground = false })
            } else {
                ElementPropertiesSheet(viewModel: viewModel, onDone: { wantsProperties = false })
                    // Başka eleman seçilince panel en üstten, yeni elemanın sayfasıyla açılsın
                    .id(viewModel.selectedElementID)
            }
        }
        .frame(width: Self.inspectorWidth)
        .background(Theme.panel)
        .clipShape(shape)
        .overlay(shape.stroke(Theme.ink, lineWidth: 1))
    }
}
