//
//  SymbolElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki tek başına bir sembol. Çerçevesine sığacak kadar büyür; boyutu kullanıcı ayarlar.
struct SymbolElementView: View {
    let properties: ElementProperties

    private var color: Color {
        properties.tintColor.flatMap(Color.init(hexString:)) ?? .primary
    }

    var body: some View {
        Image(systemName: properties.symbolName ?? "heart")
            .resizable()
            .symbolVariant(properties.isSymbolFilled ?? false ? .fill : .none)
            .scaledToFit()
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HStack(spacing: 20) {
        SymbolElementView(properties: ElementProperties(symbolName: "gearshape", tintColor: "#007AFF"))
            .frame(width: 44, height: 44)
        SymbolElementView(properties: ElementProperties(symbolName: "heart", tintColor: "#AC5135", isSymbolFilled: true))
            .frame(width: 88, height: 88)
    }
    .padding()
    .background(Theme.paper)
}
