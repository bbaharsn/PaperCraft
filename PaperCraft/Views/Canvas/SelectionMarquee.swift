//
//  SelectionMarquee.swift
//  PaperCraft
//

import SwiftUI

/// Toplu seçimde boş yerden sürüklenerek çizilen yarı saydam seçim çerçevesi. `rect` sayfa point'iyle verilir.
struct SelectionMarquee: View {
    let rect: CGRect
    let scale: CGFloat

    var body: some View {
        Rectangle()
            .fill(.blue.opacity(0.08))
            .overlay(Rectangle().stroke(.blue, lineWidth: 1 / scale))
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
            .allowsHitTesting(false)
    }
}

#Preview {
    ZStack(alignment: .topLeading) {
        SelectionMarquee(rect: CGRect(x: 20, y: 20, width: 200, height: 80), scale: 1)
    }
    .frame(width: 300, height: 200, alignment: .topLeading)
}
