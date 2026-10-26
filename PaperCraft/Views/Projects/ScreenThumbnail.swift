//
//  ScreenThumbnail.swift
//  PaperCraft
//

import SwiftUI

/// Bir ekranın küçük, dokunulamayan önizlemesi (Projelerim kartlarında).
/// Elemanlar canvas'taki gibi gerçek iPhone boyutunda yerleştirilir, sonra verilen genişliğe küçültülür.
struct ScreenThumbnail: View {
    let screen: PrototypeScreen

    /// Referans iPhone ekranı (point); canvas ile aynı.
    private let referenceSize = CGSize(width: 393, height: 852)

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / referenceSize.width

            ZStack {
                ForEach(screen.elements) { element in
                    let frame = element.frame
                    ElementView(element: element)
                        .frame(width: frame.width * referenceSize.width,
                               height: frame.height * referenceSize.height)
                        .rotationEffect(.degrees(element.properties.rotation ?? 0))
                        .position(x: (frame.x + frame.width / 2) * referenceSize.width,
                                  y: (frame.y + frame.height / 2) * referenceSize.height)
                }
            }
            .frame(width: referenceSize.width, height: referenceSize.height)
            .background(Theme.paper)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .aspectRatio(referenceSize.width / referenceSize.height, contentMode: .fit)
        .allowsHitTesting(false)
    }
}

#Preview {
    ScreenThumbnail(screen: MockScreens.login(using: try! ComponentCatalog.load()))
        .frame(width: 150)
        .paperCard()
        .padding()
        .background(Theme.background)
}
