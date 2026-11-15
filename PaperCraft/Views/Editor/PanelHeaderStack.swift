//
//  PanelHeaderStack.swift
//  PaperCraft
//

import SwiftUI

/// iPad'deki sabit panellerin başlığı: ortada başlık, sağda "Bitti", altında içerik.
/// Sayfalardaki gezinme çubuğunun yerine geçer; panel editörün gezinme yığınının içinde olduğu için
/// kendi `NavigationStack`'i olamaz.
struct PanelHeaderStack<Content: View>: View {
    let title: String
    let onDone: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                HStack {
                    Spacer()
                    Button("Bitti", action: onDone)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            Divider()
            content
        }
        .background(Theme.panel)
    }
}
