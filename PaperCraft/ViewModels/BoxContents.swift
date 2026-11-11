//
//  BoxContents.swift
//  PaperCraft
//

import CoreGraphics
import Foundation

/// Bir Kutu'nun "içindekiler"ini bulur. Kutu, Figma'daki frame gibi bir kaptır:
/// içine konan elemanlar kutu taşınınca ya da silinince onunla birlikte gelir.
///
/// Bu bağ modele kaydedilmez; her seferinde konumlardan yeniden hesaplanır. Böylece kutudan
/// çıkarılan eleman kendiliğinden ayrılır, kutunun içine bırakılan eleman kendiliğinden katılır.
/// Tasarım: `docs/superpowers/specs/2026-11-11-multi-select-design.md`.
nonisolated enum BoxContents {
    /// Kenarlarda yuvarlama farkı yüzünden dışarıda sayılmasın diye pay (point).
    static let tolerance: CGFloat = 0.5

    /// Verilen kimlikler (sabit barlar hariç) ve bunların arasındaki her Kutu'nun içindekiler.
    /// Bir eleman bir Kutu'nun içindedir, eğer: dizide kutudan sonra geliyorsa (üstünde çiziliyorsa),
    /// sabit bar değilse ve döndürülmüş hali kutunun tamamen içindeyse. İç içe kutular da sayılır.
    /// - Parameter rect: elemanın point dikdörtgeni (döndürmesiz).
    static func group(startingFrom ids: Set<UUID>, in elements: [CanvasElement],
                      rect: (CanvasElement) -> CGRect) -> Set<UUID> {
        var result = Set(elements.filter { ids.contains($0.id) && !$0.isPinned }.map(\.id))
        // Dizi sırasıyla tek geçiş yeterli: içteki kutu her zaman dıştakinden sonra gelir.
        for (boxIndex, box) in elements.enumerated() where box.type == .box && result.contains(box.id) {
            let area = rect(box).insetBy(dx: -tolerance, dy: -tolerance)
            for child in elements[(boxIndex + 1)...] where !child.isPinned {
                let childBox = SnapGuides.boundingBox(rect(child), degrees: child.properties.rotation ?? 0)
                guard area.contains(childBox) else { continue }
                result.insert(child.id)
            }
        }
        return result
    }
}
