//
//  SymbolCatalogSheet.swift
//  PaperCraft
//

import SwiftUI

/// Katalogdan sembol eklenirken açılan sayfa: kullanıcı bir sembol seçer, sayfa kapanır.
struct SymbolCatalogSheet: View {
    let symbols: [SymbolEntry]
    /// Seçilen sembolün adını dışarıya haber verir. "Vazgeç"te çağrılmaz.
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    /// Henüz seçim yok; sembole dokunmak seçimi bildirip sayfayı kapatır.
    private var selection: Binding<String> {
        Binding(
            get: { "" },
            set: { name in
                onSelect(name)
                dismiss()
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                SymbolPickerRow(symbolName: selection, symbols: symbols)
                    .padding()
            }
            .background(Theme.panel)
            .navigationTitle("Sembol Seç")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SymbolCatalogSheet(symbols: try! SymbolCatalog.load().symbols, onSelect: { _ in })
}
