//
//  TapActionSection.swift
//  PaperCraft
//

import SwiftUI

/// Özellikler sayfasındaki "Dokununca" bölümü: hiçbir şey, geri dön ya da projedeki bir sayfa.
/// Buton, görsel, üst bar sağ butonu ve alt menü sekmeleri ortak kullanır.
struct TapActionSection: View {
    @Binding var action: ElementAction
    let targets: [ScreenLink]
    var title = "Dokununca"

    var body: some View {
        Section(title) {
            row("Hiçbir şey", for: .none)
            row("Geri dön", for: .back)
            ForEach(targets) { screen in
                row(screen.name, for: .goTo(screenID: screen.id))
            }
        }
    }

    private func row(_ title: String, for option: ElementAction) -> some View {
        Button {
            action = option
        } label: {
            HStack {
                Text(title)
                Spacer()
                if action == option {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.accent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
