//
//  EditorTopBar.swift
//  PaperCraft
//

import SwiftUI

/// Editörün üst barı: sayfalara dönüş, geri al / yinele, toplu seçim, katalog butonu ve "Dene" butonu.
struct EditorTopBar: View {
    let pageName: String
    /// "‹ Sayfa adı"na basılınca sayfalara dönülür.
    let onBack: () -> Void
    var canUndo = false
    var canRedo = false
    var onUndo: () -> Void = {}
    var onRedo: () -> Void = {}
    /// Toplu seçim modu açık mı? Açıkken düğme dolu görünür.
    var isMultiSelecting = false
    var onToggleMultiSelect: () -> Void = {}
    /// [≋] butonuna basılınca ne olacağını dışarıdan alırız.
    let onToggleCatalog: () -> Void
    /// "Dene" butonuna basılınca ne olacağını dışarıdan alırız.
    let onPreview: () -> Void

    var body: some View {
        HStack {
            backButton
            Spacer(minLength: 8)
            undoRedoButtons
            multiSelectButton
            catalogButton
            previewButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    /// Sayfa adı uzunsa sonu "…" ile kısalır; butonlar hep sığar.
    private var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                Text(pageName)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(Theme.ink)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sayfalara dön")
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

    /// Toplu seçim modunu açıp kapatır; açıkken zemin koyu, ikon açık renk.
    private var multiSelectButton: some View {
        Button(action: onToggleMultiSelect) {
            Image(systemName: "square.on.square.dashed")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isMultiSelecting ? Theme.paper : Theme.ink)
                .frame(width: 44, height: 44)
                .background(isMultiSelecting ? Theme.ink : Theme.panel, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toplu seçim")
        .accessibilityAddTraits(isMultiSelecting ? .isSelected : [])
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
    VStack {
        EditorTopBar(pageName: "Ana Sayfa", onBack: {}, canUndo: true, onToggleCatalog: {}, onPreview: {})
        EditorTopBar(pageName: "Ana Sayfa", onBack: {}, isMultiSelecting: true, onToggleCatalog: {}, onPreview: {})
    }
    .background(Theme.background)
}
