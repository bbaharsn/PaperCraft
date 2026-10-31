//
//  SymbolPickerRow.swift
//  PaperCraft
//

import SwiftUI

/// Sembol kataloğundaki ikonları aşağı doğru uzanan bir ızgara olarak gösterir.
struct SymbolPickerRow: View {
    @Binding var symbolName: String
    let symbols: [SymbolEntry]

    /// Ekran genişliğine sığdığı kadar sütun açılır.
    private let columns = [GridItem(.adaptive(minimum: 40), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(symbols, id: \.name) { symbol in
                let isSelected = symbol.name == symbolName
                Button {
                    symbolName = symbol.name
                } label: {
                    Image(systemName: symbol.name)
                        .font(.system(size: 18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .foregroundStyle(isSelected ? Theme.paper : Theme.ink)
                        .background(isSelected ? Theme.ink : Theme.paper,
                                    in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.ink, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
    }
}

#Preview {
    @Previewable @State var symbolName = "heart"
    SymbolPickerRow(symbolName: $symbolName, symbols: try! SymbolCatalog.load().symbols)
        .padding()
}
