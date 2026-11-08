//
//  ScreenThumbnail.swift
//  PaperCraft
//

import SwiftUI

/// Bir ekranın küçük, dokunulamayan önizlemesi (Projelerim ve sayfa kartlarında).
/// Elemanlar canvas'taki gibi gerçek iPhone boyutunda yerleştirilir, sonra verilen genişliğe küçültülür.
/// Uzun sayfa gerçek uzunluğunda görünür; `maxScreens`'i aşan kısmı soluklaşarak kesilir.
struct ScreenThumbnail: View {
    let screen: PrototypeScreen
    /// En fazla kaç ekran boyu gösterilsin (sayfa kartlarında 2, Projelerim'de 1).
    var maxScreens: Double = 2

    /// Referans iPhone ekranı (point); canvas ile aynı.
    private let referenceSize = CGSize(width: 393, height: 852)

    /// Gösterilen yükseklik (tuval point'i).
    private var shownHeight: CGFloat {
        CGFloat(min(screen.contentHeight, maxScreens)) * referenceSize.height
    }

    /// Sabit alt bar (ekranın alt yarısındaki sabit eleman) kartın en altına iner; uzun sayfada
    /// ilk ekranın ortasında kalmasın. Üstteki sabit barlar ve diğer elemanlar yerinde kalır (ekran birimi).
    private func pinnedShift(for element: CanvasElement) -> Double {
        guard element.isPinned, element.frame.y + element.frame.height / 2 > 0.5 else { return 0 }
        return min(screen.contentHeight, maxScreens) - 1
    }

    /// Sayfa gösterilenden uzun mu? O zaman alt kısım soluklaşır.
    private var isCut: Bool { screen.contentHeight > maxScreens }

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / referenceSize.width
            let pageHeight = CGFloat(screen.contentHeight) * referenceSize.height

            ZStack {
                ForEach(screen.elements) { element in
                    let frame = element.frame
                    ElementView(element: element)
                        .frame(width: frame.width * referenceSize.width,
                               height: frame.height * referenceSize.height)
                        .rotationEffect(.degrees(element.properties.rotation ?? 0))
                        .position(x: (frame.x + frame.width / 2) * referenceSize.width,
                                  y: (frame.y + frame.height / 2 + pinnedShift(for: element)) * referenceSize.height)
                }
            }
            .frame(width: referenceSize.width, height: pageHeight, alignment: .topLeading)
            .background(ScreenBackgroundView(background: screen.background))
            .frame(width: referenceSize.width, height: shownHeight, alignment: .top)
            .clipped()
            .mask {
                LinearGradient(stops: [.init(color: .black, location: isCut ? 0.85 : 1),
                                       .init(color: .black.opacity(isCut ? 0 : 1), location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .aspectRatio(referenceSize.width / shownHeight, contentMode: .fit)
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
