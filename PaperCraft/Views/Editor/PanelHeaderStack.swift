//
//  PanelHeaderStack.swift
//  PaperCraft
//

import SwiftUI

/// iPad'deki sabit panellerin başlığı: ortada başlık, sağda "Bitti", altında içerik.
/// Sayfalardaki gezinme çubuğunun yerine geçer; panel editörün gezinme yığınının içinde olduğu için
/// kendi `NavigationStack`'i olamaz. Alt sayfalar (`PanelLink`) panelin kendi yığınına (`PanelNavigator`)
/// eklenir: açıkken başlık alt sayfanınkine döner, solda "Geri" çıkar.
struct PanelHeaderStack<Content: View>: View {
    let title: String
    let onDone: () -> Void
    @ViewBuilder let content: Content

    @State private var navigator = PanelNavigator()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ZStack {
                if let page = navigator.top {
                    page.content
                        .id(page.id)
                        .transition(.move(edge: .trailing))
                } else {
                    content
                        .transition(.move(edge: .leading))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .background(Theme.panel)
        .environment(\.panelNavigator, navigator)
    }

    private var header: some View {
        ZStack {
            Text(navigator.top?.title ?? title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .padding(.horizontal, 80)
            HStack {
                if !navigator.pages.isEmpty {
                    Button {
                        withAnimation(.snappy) { navigator.pop() }
                    } label: {
                        Label("Geri", systemImage: "chevron.left")
                            .labelStyle(.titleAndIcon)
                    }
                    .font(.system(size: 17))
                }
                Spacer()
                Button("Bitti", action: onDone)
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }
}
