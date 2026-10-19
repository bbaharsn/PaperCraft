//
//  EditorTopBar.swift
//  PaperCraft
//

import SwiftUI

/// Editörün üst barı: logo, katalog butonu ve "Dene" butonu.
struct EditorTopBar: View {
    /// [≋] butonuna basılınca ne olacağını dışarıdan alırız.
    let onToggleCatalog: () -> Void
    /// "Dene" butonuna basılınca ne olacağını dışarıdan alırız.
    let onPreview: () -> Void

    var body: some View {
        HStack {
            logo
            Spacer()
            catalogButton
            previewButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    /// İki Text'i `+` ile birleştiriyoruz: nokta farklı renkte.
    private var logo: some View {
        (Text("papercraft").foregroundStyle(Theme.ink)
         + Text(".").foregroundStyle(Theme.accent))
            .font(Theme.logoFont(size: 24))
    }

    private var catalogButton: some View {
        Button(action: onToggleCatalog) {
            Image(systemName: "square.3.layers.3d")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 1))
        }
    }

    private var previewButton: some View {
        Button(action: onPreview) {
            Text("Dene")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.paper)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    EditorTopBar(onToggleCatalog: {}, onPreview: {})
        .background(Theme.background)
}
