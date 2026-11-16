//
//  ProjectCard.swift
//  PaperCraft
//

import SwiftUI

/// Projelerim'deki tek bir proje: ilk ekranının küçük önizlemesi, adı ve son düzenleme zamanı.
struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScreenThumbnail(screen: project.firstScreen, maxScreens: 1,
                            referenceSize: project.device.canvasSize)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .paperCard()

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                // "iPad · 5 dakika önce" gibi
                HStack(spacing: 4) {
                    Image(systemName: project.device.symbolName)
                    Text(project.device.title)
                    Text("·")
                    Text(project.updatedAt, format: .relative(presentation: .named))
                }
                .font(.system(size: 13))
                .foregroundStyle(Theme.ink.opacity(0.6))
                .lineLimit(1)
            }
            .padding(.horizontal, 2)
        }
    }
}
