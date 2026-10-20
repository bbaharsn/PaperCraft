//
//  SymbolPickerRow.swift
//  PaperCraft
//

import SwiftUI

/// Sembol kataloğundaki ikonları yatay kaydırılan bir şerit olarak gösterir.
struct SymbolPickerRow: View {
    @Binding var symbolName: String
    let symbols: [SymbolEntry]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(symbols, id: \.name) { symbol in
                    let isSelected = symbol.name == symbolName
                    Button {
                        symbolName = symbol.name
                    } label: {
                        Image(systemName: symbol.name)
                            .font(.system(size: 18))
                            .frame(width: 40, height: 40)
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
}

#Preview {
    @Previewable @State var symbolName = "heart"
    SymbolPickerRow(symbolName: $symbolName, symbols: try! SymbolCatalog.load().symbols)
        .padding()
}
