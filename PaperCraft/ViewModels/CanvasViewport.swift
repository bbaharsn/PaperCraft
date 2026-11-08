//
//  CanvasViewport.swift
//  PaperCraft
//

import CoreGraphics

/// Canvas'ın yakınlaştırma ve kaydırma durumu. Sadece görünümü değiştirir; projeye kaydedilmez.
///
/// `zoom` 1 iken kart alana tam sığar. `pan`, kartın ortalanmış yerinden ne kadar kaydığıdır (ekran point'i).
/// `scroll`, kartın içindeki sayfanın ne kadar aşağı kaydırıldığıdır (tuval point'i; 852 = bir ekran).
struct CanvasViewport: Equatable {
    /// Kart, sığdığı boyutun en fazla 4 katına büyür; sığdığından küçülmez.
    static let zoomRange: ClosedRange<CGFloat> = 1...4
    /// Büyütülmüş kart kenarından bu kadar fazla kaydırılabilir; kenar parmağın altında kalmasın.
    static let edgeMargin: CGFloat = 40

    /// Bir ekranın yüksekliği (tuval point'i).
    static let screenHeight: CGFloat = 852

    var zoom: CGFloat = 1
    var pan: CGSize = .zero
    var scroll: CGFloat = 0

    /// Sayfa en fazla ne kadar kaydırılabilir: gerçek uzunluğunun bir ekran fazlası,
    /// yani en altta her zaman bir boş ekran daha var. `contentHeight` ekran yüksekliği birimiyle.
    static func maxScroll(contentHeight: Double) -> CGFloat {
        CGFloat(contentHeight) * screenHeight
    }

    var isZoomed: Bool { zoom > Self.zoomRange.lowerBound + 0.001 }

    /// İki parmakla yakınlaştırma. Parmakların arasındaki nokta (`anchor`, alanın ortasına göre)
    /// kartın aynı yerinde kalır; böylece neresi büyütülüyorsa orası ekranda kalır.
    /// - Parameters:
    ///   - start: Hareket başladığındaki durum.
    ///   - cardSize: Kartın `zoom` 1'deki boyutu.
    ///   - available: Canvas alanının boyutu.
    static func pinched(from start: CanvasViewport, magnification: CGFloat, anchor: CGPoint,
                        cardSize: CGSize, available: CGSize) -> CanvasViewport {
        let zoom = min(max(start.zoom * magnification, zoomRange.lowerBound), zoomRange.upperBound)
        let ratio = zoom / start.zoom
        let pan = CGSize(width: anchor.x - (anchor.x - start.pan.width) * ratio,
                         height: anchor.y - (anchor.y - start.pan.height) * ratio)
        return CanvasViewport(zoom: zoom, pan: pan, scroll: start.scroll)
            .clamped(cardSize: cardSize, available: available)
    }

    /// Boş yerde tek parmakla sürükleme. Büyütülmüş kart önce kendi sınırına kadar kayar;
    /// artan dikey hareket sayfayı kaydırır (parmak yukarı → sayfa aşağı iner). Artan yatay hareket atılır.
    /// - Parameters:
    ///   - scale: Ekran point'inin tuval point'ine oranı (kartın o anki küçültme × yakınlaştırma).
    ///   - contentHeight: Sayfanın gerçek uzunluğu, ekran yüksekliği birimiyle.
    static func dragged(from start: CanvasViewport, by translation: CGSize, cardSize: CGSize,
                        available: CGSize, scale: CGFloat, contentHeight: Double) -> CanvasViewport {
        let wantedPanY = start.pan.height + translation.height
        var result = CanvasViewport(zoom: start.zoom,
                                    pan: CGSize(width: start.pan.width + translation.width, height: wantedPanY),
                                    scroll: start.scroll)
            .clamped(cardSize: cardSize, available: available)
        let leftover = wantedPanY - result.pan.height
        let scroll = start.scroll - leftover / scale
        result.scroll = min(max(scroll, 0), maxScroll(contentHeight: contentHeight))
        return result
    }

    /// Kart ekrandan kaçmasın: alandan büyük olduğu yönde kenarına kadar (biraz fazlası) kaydırılır,
    /// küçük olduğu yönde ortada kalır.
    func clamped(cardSize: CGSize, available: CGSize) -> CanvasViewport {
        func limit(_ card: CGFloat, _ space: CGFloat) -> CGFloat {
            let scaled = card * zoom
            return scaled > space ? (scaled - space) / 2 + Self.edgeMargin : 0
        }
        let maxX = limit(cardSize.width, available.width)
        let maxY = limit(cardSize.height, available.height)
        return CanvasViewport(zoom: zoom,
                              pan: CGSize(width: min(max(pan.width, -maxX), maxX),
                                          height: min(max(pan.height, -maxY), maxY)),
                              scroll: scroll)
    }
}
