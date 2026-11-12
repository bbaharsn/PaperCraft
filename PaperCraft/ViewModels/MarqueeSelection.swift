//
//  MarqueeSelection.swift
//  PaperCraft
//

import CoreGraphics
import Foundation

/// Toplu seçimde boş yerden sürüklenerek çizilen seçim çerçevesinin hangi elemanları seçtiğini bulur.
nonisolated enum MarqueeSelection {
    /// Çerçevenin **değdiği** elemanlar (döndürülmüşse dönmüş halinin kapladığı kutuyla). Elemanın
    /// gerçek kutusu göründüğünden geniş olabildiği için (ör. yazı) tamamen içine almak gerekmez.
    /// Çerçeveyi tamamen kapsayan eleman seçilmez: arka plandaki büyük bir kutunun içine çizilen
    /// çerçeve kutunun kendisini değil, içindekileri seçer (Figma'daki gibi). Sabit barlar seçilmez.
    /// - Parameter rect: elemanın point dikdörtgeni (döndürmesiz); `marquee` ile aynı koordinatlarda.
    static func ids(in marquee: CGRect, elements: [CanvasElement],
                    rect: (CanvasElement) -> CGRect) -> Set<UUID> {
        let area = marquee.standardized
        guard area.width > 0 || area.height > 0 else { return [] }
        return Set(elements.filter { element in
            guard !element.isPinned else { return false }
            let box = SnapGuides.boundingBox(rect(element), degrees: element.properties.rotation ?? 0)
            return box.intersects(area) && !box.contains(area)
        }.map(\.id))
    }
}
