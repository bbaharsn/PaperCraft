//
//  TabItemPropertiesView.swift
//  PaperCraft
//

import SwiftUI

/// Alt menüde tek bir sekmenin yazısını ve ikonunu düzenleyen sayfa.
/// Alt menünün Özellikler sayfasındaki sekme listesinden açılır.
struct TabItemPropertiesView: View {
    let viewModel: EditorViewModel
    let index: Int

    /// Sekme silinince sayfa kapanıp listeye dönülür.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Yazı") {
                TextField("Örn. Ana Sayfa", text: viewModel.tabBinding(at: index, \.text))
            }

            Section("İkon") {
                SymbolPickerRow(symbolName: viewModel.tabBinding(at: index, \.symbolName),
                                symbols: viewModel.symbolCatalog.symbols)
            }

            Section {
                Button("Sekmeyi Sil", role: .destructive) {
                    viewModel.removeSelectedTab(at: index)
                    dismiss()
                }
                .disabled((viewModel.selectedElement?.properties.items?.count ?? 0)
                          <= TabItem.allowedCount.lowerBound)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.panel)
        .navigationTitle("Sekme \(index + 1)")
    }
}
