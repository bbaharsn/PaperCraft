//
//  CatalogCardFrame.swift
//  PaperCraft
//

import SwiftUI

/// Katalog kartlarının ortak görünümü: üstte küçük bir çizim, altta adı.
struct CatalogCardFrame<Preview: View>: View {
    let title: String
    /// Kartın eğim açısı (derece). Kartlar dağınık kağıtlar gibi görünsün diye.
    let tilt: Double
    @ViewBuilder let preview: Preview

    var body: some View {
        VStack(spacing: 14) {
            preview
                .frame(height: 50)
            Text(title)
                .font(.system(size: 15, weight: .semibold).italic())
                .foregroundStyle(Theme.ink)
        }
        .frame(width: 104, height: 128)
        .paperCard(cornerRadius: 8)
        .rotationEffect(.degrees(tilt))
    }
}

#Preview {
    CatalogCardFrame(title: "arka plan", tilt: -2) {
        Circle().fill(Theme.accent).frame(width: 40, height: 40)
    }
    .padding(30)
    .background(Theme.panel)
}
