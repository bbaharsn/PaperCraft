//
//  SelectionToolbar.swift
//  PaperCraft
//

import SwiftUI

/// Bir eleman seçiliyken canvas'ın altında beliren işlem butonları.
/// Şimdilik sadece "Sil" var; ileride "Klonla" ve "Düzenle" eklenecek.
struct SelectionToolbar: View {
    let onDelete: () -> Void

    var body: some View {
        Button(action: onDelete) {
            Label("Sil", systemImage: "trash")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.paper)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(Theme.accent, in: Capsule())
                .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.5))
        }
    }
}

#Preview {
    SelectionToolbar(onDelete: {})
        .padding()
        .background(Theme.background)
}
