//
//  CatalogCard.swift
//  PaperCraft
//

import SwiftUI

/// Katalogdaki tek bir bileşen kartı: üstte küçük bir önizleme, altta adı.
struct CatalogCard: View {
    let definition: ComponentDefinition
    /// Kartın eğim açısı (derece). Kartlar dağınık kağıtlar gibi görünsün diye.
    let tilt: Double

    var body: some View {
        VStack(spacing: 14) {
            preview
                .frame(height: 50)
            Text(definition.displayName)
                .font(.system(size: 15, weight: .semibold).italic())
                .foregroundStyle(Theme.ink)
        }
        .frame(width: 104, height: 128)
        .paperCard(cornerRadius: 8)
        .rotationEffect(.degrees(tilt))
    }

    /// Bazı bileşenlerin tasarımdaki özel çizimi var; diğerleri katalogdaki ikonu kullanır.
    @ViewBuilder
    private var preview: some View {
        switch definition.type {
        case .button:
            Capsule()
                .fill(Theme.accent)
                .frame(width: 64, height: 26)
        case .text:
            Text("Aa")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.ink)
        case .textField:
            RoundedRectangle(cornerRadius: 4)
                .stroke(Theme.ink, lineWidth: 1)
                .frame(width: 70, height: 22)
        default:
            Image(systemName: definition.paletteSymbol)
                .font(.system(size: 30))
                .foregroundStyle(Theme.ink)
        }
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    HStack(spacing: 16) {
        ForEach(catalog.components.prefix(3), id: \.type) { definition in
            CatalogCard(definition: definition, tilt: -2)
        }
    }
    .padding(30)
    .background(Theme.panel)
}
