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

    /// Özellikler sayfasının yarım açıkken yüksekliği (point).
    private static let propertiesSheetHeight: CGFloat = 340

    /// Seçili eleman bir buton mu? Öyleyse Özellikler sayfası açık durur.
    /// Sayfa aşağı kaydırılıp kapatılırsa seçim de kalkar.
    private var isEditingButton: Binding<Bool> {
        Binding(
            get: { viewModel.selectedElement?.type == .button },
            set: { isOpen in
                if !isOpen { viewModel.select(nil) }
            }
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
            CanvasView(viewModel: viewModel)
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
                // Sayfa açıkken canvas yukarıda küçülür, böylece altında kalmaz.
                .padding(.bottom, isEditingButton.wrappedValue ? Self.propertiesSheetHeight : 0)
                .animation(.snappy, value: viewModel.selectedElementID)

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
        .sheet(isPresented: isEditingButton) {
            ButtonPropertiesSheet(viewModel: viewModel)
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
