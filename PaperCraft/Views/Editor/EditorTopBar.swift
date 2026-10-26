//
//  EditorTopBar.swift
//  PaperCraft
//

import SwiftUI

/// Editörün üst barı: logo, geri al / yinele, katalog butonu ve "Dene" butonu.
struct EditorTopBar: View {
    var canUndo = false
    var canRedo = false
    var onUndo: () -> Void = {}
    var onRedo: () -> Void = {}
    /// [≋] butonuna basılınca ne olacağını dışarıdan alırız.
    let onToggleCatalog: () -> Void
    /// "Dene" butonuna basılınca ne olacağını dışarıdan alırız.
    let onPreview: () -> Void

    var body: some View {
        HStack {
            logo
            Spacer()
            undoRedoButtons
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

    /// Geri al ve yinele tek bir kutuda yan yana; yapılacak bir şey yoksa soluk görünür.
    /// Klavyede (iPad, Mac) ⌘Z ve ⌘⇧Z ile de çalışır.
    private var undoRedoButtons: some View {
        HStack(spacing: 0) {
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .frame(width: 36, height: 44)
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!canUndo)
            .opacity(canUndo ? 1 : 0.3)   // düz buton stilinde soluklaşma kendiliğinden olmuyor
            .accessibilityLabel("Geri al")

            Rectangle()
                .fill(Theme.ink.opacity(0.3))
                .frame(width: 1, height: 22)

            Button(action: onRedo) {
                Image(systemName: "arrow.uturn.forward")
                    .frame(width: 36, height: 44)
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(!canRedo)
            .opacity(canRedo ? 1 : 0.3)
            .accessibilityLabel("Yinele")
        }
        .buttonStyle(.plain)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Theme.ink)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 1))
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
    EditorTopBar(canUndo: true, onToggleCatalog: {}, onPreview: {})
        .background(Theme.background)
}
