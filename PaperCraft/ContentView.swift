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
    }

    /// Kataloğu yükleyip örnek ekranla bir editör hazırlar.
    /// Katalog okunamazsa boş katalog ve boş ekranla açılır (çökmez).
    private static func makeEditor() -> EditorViewModel {
        guard let catalog = try? ComponentCatalog.load() else {
            return EditorViewModel(catalog: .empty, screen: PrototypeScreen(name: "Boş Ekran"))
        }
        return EditorViewModel(catalog: catalog, screen: MockScreens.login(using: catalog))
    }
}

#Preview {
    ContentView()
}
