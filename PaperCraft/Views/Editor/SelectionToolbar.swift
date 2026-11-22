//
//  SelectionToolbar.swift
//  PaperCraft
//

import SwiftUI

/// Bir eleman seçiliyken canvas'ın altında beliren işlem butonları: "Çoğalt" ve "Sil"
/// (içi dolu bir kutuda önce "Kutuyu çöz"); toplu seçimde "Kutuya al" ve "Sil".
struct SelectionToolbar: View {
    /// `nil` değilse "Kutuya al" gösterilir: seçilenleri saran bir kutu ekler.
    var onWrap: (() -> Void)? = nil
    /// `nil` değilse "Kutuyu çöz" gösterilir: kutuyu siler, içindekiler kalır.
    var onUngroup: (() -> Void)? = nil
    /// `nil` değilse toplu seçimde yuvarlak Özellikler düğmesi gösterilir (seçilenler aynı türdeyse).
    var onEditProperties: (() -> Void)? = nil
    /// `nil` ise "Çoğalt" gösterilmez (ör. üst bar ve alt menü çoğaltılmaz).
    var onDuplicate: (() -> Void)? = nil
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if let onWrap {
                Button(action: onWrap) {
                    Label("Kutuya al", systemImage: "square.dashed")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 18)
                        .frame(height: 40)
                        .background(Theme.panel, in: Capsule())
                        .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.5))
                }
            }

            if let onEditProperties {
                // Yer kaplamasın diye yalnızca ikon; "Kutuya al" ve "Sil" ile birlikte dar ekrana sığar.
                Button(action: onEditProperties) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 40, height: 40)
                        .background(Theme.panel, in: Circle())
                        .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
                }
                .accessibilityLabel("Özellikler")
            }

            if let onUngroup {
                Button(action: onUngroup) {
                    Label("Kutuyu çöz", systemImage: "square.slash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 18)
                        .frame(height: 40)
                        .background(Theme.panel, in: Capsule())
                        .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.5))
                }
            }

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
        SelectionToolbar(onWrap: {}, onDelete: {})
        SelectionToolbar(onWrap: {}, onEditProperties: {}, onDelete: {})
        SelectionToolbar(onUngroup: {}, onDuplicate: {}, onDelete: {})
    }
    .padding()
    .background(Theme.background)
}
