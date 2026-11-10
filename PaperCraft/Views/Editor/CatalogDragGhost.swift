//
//  CatalogDragGhost.swift
//  PaperCraft
//

import SwiftUI

/// Katalogdan sürüklenen eleman: canvas'taki boyu ve görünüşüyle parmağın altında yüzer.
/// Dokunuşları almaz; bırakınca yerine asıl eleman eklenir.
struct CatalogDragGhost: View {
    let element: CanvasElement
    /// Parmağın ekrandaki yeri (global).
    let location: CGPoint
    /// Ekran point'inin tuval point'ine oranı; eleman canvas'taki boyunda görünsün.
    let scale: CGFloat

    var body: some View {
        let reference = CanvasMapping.referenceSize
        let size = CGSize(width: element.frame.width * reference.width,
                          height: element.frame.height * reference.height)

        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            ElementView(element: element)
                .frame(width: size.width, height: size.height)
                .rotationEffect(.degrees(element.properties.rotation ?? 0))
                .scaleEffect(scale)
                .shadow(color: Theme.ink.opacity(0.25), radius: 8, y: 4)
                .opacity(0.9)
                .position(x: location.x - origin.x, y: location.y - origin.y)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
