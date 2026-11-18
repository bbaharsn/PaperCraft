//
//  ProjectSidebarRow.swift
//  PaperCraft
//

import SwiftUI

/// iPad'de Projelerim kenar listesindeki tek satır: ilk sayfanın küçük kâğıdı, adı, cihazı ve son düzenleme zamanı.
/// Seçili satır kâğıt rengine döner; seçili proje sağda sayfalarıyla açılır.
struct ProjectSidebarRow: View {
    let project: Project
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ScreenThumbnail(screen: project.firstScreen, maxScreens: 1,
                            referenceSize: project.device.canvasSize)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.ink.opacity(0.25), lineWidth: 1))
                // iPhone ve iPad küçük resimleri aynı yüksekliğe sığsın; satırlar hizalı kalsın
                .frame(width: 40, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: project.device.symbolName)
                    Text(project.device.title)
                    Text("·")
                    Text(project.updatedAt, format: .relative(presentation: .named))
                }
                .font(.system(size: 13))
                .foregroundStyle(Theme.ink.opacity(0.65))
                .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.paper)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.ink.opacity(0.15), lineWidth: 1))
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
