//
//  ContentView.swift
//  PaperCraft
//
//  Created by Bahar Şen on 13.10.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = ContentView.makeEditor()
    /// Alt katalog açık mı? Sadece bu ekranı ilgilendiren bir görünüm durumu.
    @State private var isCatalogOpen = false

    /// Kullanıcı Özellikler sayfasını istedi mi (çift dokunuş)?
    /// Tek dokunuş sadece seçer; sayfa açılmadan taşınır ve boyutlandırılır.
    @State private var wantsProperties = false

    /// Özellikler sayfasının yarım açıkken yüksekliği (point).
    private static let propertiesSheetHeight: CGFloat = 340

    /// Sayfa, istendiğinde ve seçili elemanın bir Özellikler sayfası olduğunda açıktır.
    /// Aşağı kaydırılıp ya da "Bitti" ile kapatılırsa seçim kalır, sadece sayfa kapanır.
    private var isShowingProperties: Binding<Bool> {
        Binding(
            get: {
                guard wantsProperties, let type = viewModel.selectedElement?.type else { return false }
                return ElementPropertiesSheet.hasSheet(for: type)
            },
            set: { wantsProperties = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorTopBar(
                onToggleCatalog: {
                    withAnimation(.snappy) {
                        isCatalogOpen.toggle()
                    }
                },
                onPreview: { /* T6'da önizleme açılacak */ }
            )
            // Canvas yukarı kaydığında üst barın altından geçsin, üstüne binmesin
            .zIndex(1)
            CanvasView(viewModel: viewModel,
                       onDoubleTap: { wantsProperties = true },
                       // Sayfa açıkken canvas küçülmez; seçili eleman sayfanın altında kalırsa yukarı kayar.
                       bottomInset: isShowingProperties.wrappedValue ? Self.propertiesSheetHeight : 0)
                .padding()
                // overlay: canvas'ın boyutunu değiştirmeden üstüne yüzer
                .overlay(alignment: .bottom) {
                    if viewModel.selectedElementID != nil {
                        SelectionToolbar(onDelete: {
                            viewModel.deleteSelectedElement()
                        })
                        .padding(.bottom, 32)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.snappy, value: viewModel.selectedElementID)
                .animation(.snappy, value: wantsProperties)

            if isCatalogOpen {
                CatalogPanel(
                    catalog: viewModel.catalog,
                    onSelect: { type in
                        viewModel.addElement(of: type)
                    }
                )
                    .transition(.move(edge: .bottom))
            }
        }
        .background(Theme.background)
        // Seçim tamamen kalkınca istek de sıfırlanır; yoksa sonraki tek dokunuş sayfayı açardı.
        .onChange(of: viewModel.selectedElementID) { _, newID in
            if newID == nil { wantsProperties = false }
        }
        .sheet(isPresented: isShowingProperties) {
            ElementPropertiesSheet(viewModel: viewModel)
                .presentationDetents([.height(Self.propertiesSheetHeight), .large])
                .presentationDragIndicator(.visible)
                // Sayfa açıkken de canvas'a dokunup başka eleman seçilebilsin.
                .presentationBackgroundInteraction(.enabled(upThrough: .height(Self.propertiesSheetHeight)))
        }
    }

    /// Katalogları yükleyip örnek ekranla bir editör hazırlar.
    /// Katalog okunamazsa boş katalog ve boş ekranla açılır (çökmez).
    private static func makeEditor() -> EditorViewModel {
        guard let catalog = try? ComponentCatalog.load() else {
            return EditorViewModel(catalog: .empty, screen: PrototypeScreen(name: "Boş Ekran"))
        }
        let symbols = (try? SymbolCatalog.load()) ?? .empty
        return EditorViewModel(catalog: catalog,
                               symbolCatalog: symbols,
                               screen: MockScreens.login(using: catalog))
    }
}

#Preview {
    ContentView()
}
