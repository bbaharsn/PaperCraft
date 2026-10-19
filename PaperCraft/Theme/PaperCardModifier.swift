//
//  PaperCardModifier.swift
//  PaperCraft
//

import SwiftUI

/// Kağıt görünümü: krem zemin, kahve kenarlık ve keskin (bulanık olmayan) gölge.
/// Canvas'ta ve katalog kartlarında aynı stil kullanılır.
struct PaperCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        content
            .background(Theme.paper, in: shape)
            .overlay(shape.stroke(Theme.ink, lineWidth: 1.5))
            .background(shape.fill(Theme.ink).offset(Theme.shadowOffset))
    }
}

extension View {
    /// Görünüme kağıt kart stilini uygular: `.paperCard()`
    func paperCard(cornerRadius: CGFloat = Theme.cornerRadius) -> some View {
        modifier(PaperCardModifier(cornerRadius: cornerRadius))
    }
}
