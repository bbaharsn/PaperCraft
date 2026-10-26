//
//  SelectionToolbar.swift
//  PaperCraft
//

import SwiftUI

/// Bir eleman seçiliyken canvas'ın altında beliren işlem butonları: "Çoğalt" ve "Sil".
struct SelectionToolbar: View {
    /// `nil` ise "Çoğalt" gösterilmez (ör. üst bar ve alt menü çoğaltılmaz).
    var onDuplicate: (() -> Void)? = nil
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if let onDuplicate {
                Button(action: onDuplicate) {
                    Label("Çoğalt", systemImage: "plus.square.on.square")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 18)
                        .frame(height: 40)
                        .background(Theme.panel, in: Capsule())
                        .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.5))
                }
                .keyboardShortcut("d", modifiers: .command)
            }

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
}

#Preview {
    VStack(spacing: 20) {
        SelectionToolbar(onDuplicate: {}, onDelete: {})
        SelectionToolbar(onDelete: {})
    }
    .padding()
    .background(Theme.background)
}
