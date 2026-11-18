//
//  PanelLink.swift
//  PaperCraft
//

import SwiftUI

/// Özellikler'de bir alt sayfa açan satır. iPad panelinde sayfayı panelin içine açar;
/// iPhone'daki sayfada (kendi `NavigationStack`'i var) normal `NavigationLink` gibi davranır.
/// Alt sayfanın başlığı burada verilir; alt sayfa kendisi `navigationTitle` koymaz,
/// yoksa panelde editörün başlığını değiştirir.
struct PanelLink<Label: View, Destination: View>: View {
    let title: String
    @ViewBuilder let destination: () -> Destination
    @ViewBuilder let label: () -> Label

    @Environment(\.panelNavigator) private var panel

    var body: some View {
        if let panel {
            Button {
                withAnimation(.snappy) {
                    panel.push(PanelPage(title: title, content: AnyView(destination())))
                }
            } label: {
                HStack {
                    label()
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                destination()
                    .navigationTitle(title)
            } label: {
                label()
            }
        }
    }
}
