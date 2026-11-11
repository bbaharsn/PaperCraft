//
//  GroupOutline.swift
//  PaperCraft
//

import SwiftUI

/// Toplu seçimdeki bütün elemanları saran tek, ince ve düz çerçeve. `rect` sayfa point'iyle verilir.
struct GroupOutline: View {
    let rect: CGRect
    let scale: CGFloat

    var body: some View {
        Rectangle()
            .stroke(.blue, lineWidth: 1 / scale)
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
            .allowsHitTesting(false)
    }
}

#Preview {
    ZStack(alignment: .topLeading) {
        GroupOutline(rect: CGRect(x: 20, y: 20, width: 200, height: 80), scale: 1)
    }
    .frame(width: 300, height: 200, alignment: .topLeading)
}
