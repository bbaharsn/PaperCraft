//
//  GroupResize.swift
//  PaperCraft
//

import CoreGraphics

/// Toplu seçimi bir köşesinden çekerek oranı koruyarak büyütme/küçültme hesabı (sayfa point'i).
/// Karşı köşe yerinde kalır; her eleman ona göre aynı oranla ölçeklenir, aradaki boşluklar da.
nonisolated enum GroupResize {
    /// Çekilen köşenin karşısındaki köşe: ölçekleme bu noktanın etrafında yapılır.
    static func anchor(of corner: ResizeCorner, in rect: CGRect) -> CGPoint {
        CGPoint(x: corner.isLeading ? rect.maxX : rect.minX,
                y: corner.isTop ? rect.maxY : rect.minY)
    }

    /// Parmağın başlangıçtan beri toplam hareketine (`translation`) göre ölçek. Hangi kenar daha çok
    /// değiştiyse o esas alınır. Grup sayfanın yanlarından ve üstünden taşmaz (aşağıda sayfa uzar),
    /// `minimumScale`'in altına inmez.
    static func scale(dragging corner: ResizeCorner, by translation: CGSize, rect: CGRect,
                      canvasWidth: CGFloat, minimumScale: CGFloat) -> CGFloat {
        guard rect.width > 0, rect.height > 0 else { return 1 }
        let dx = corner.isLeading ? -translation.width : translation.width
        let dy = corner.isTop ? -translation.height : translation.height
        var scale = max((rect.width + dx) / rect.width, (rect.height + dy) / rect.height)

        let anchor = anchor(of: corner, in: rect)
        scale = min(scale, corner.isLeading ? anchor.x / rect.width : (canvasWidth - anchor.x) / rect.width)
        if corner.isTop {
            scale = min(scale, anchor.y / rect.height)
        }
        return max(scale, minimumScale)
    }

    /// Dikdörtgeni `anchor` etrafında `scale` kadar büyütür.
    static func scaled(_ rect: CGRect, by scale: CGFloat, around anchor: CGPoint) -> CGRect {
        CGRect(x: anchor.x + (rect.minX - anchor.x) * scale,
               y: anchor.y + (rect.minY - anchor.y) * scale,
               width: rect.width * scale,
               height: rect.height * scale)
    }
}
