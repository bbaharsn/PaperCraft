//
//  PressDimmingButtonStyle.swift
//  PaperCraft
//

import SwiftUI

/// Önizlemedeki butonlar için: görünüm aynı kalır, basılıyken hafifçe kararır (iOS'taki gibi).
struct PressDimmingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
