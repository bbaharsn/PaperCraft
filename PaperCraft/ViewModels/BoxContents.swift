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

    /// Bırakılan kutuların altında kalan ve tamamen içlerine düşen elemanları, kutunun hemen üstüne taşır.
    /// Böylece bir kutu sayfada duran elemanların üstüne sürüklenince onları örtmez, onlar kutunun
    /// içindekiler olur. Taşınan elemanların kendi aralarındaki sırası korunur.
    /// - Parameters:
    ///   - movedIDs: Az önce taşınan elemanlar; bunların arasındaki kutular bakılır, kendileri yer değiştirmez.
    ///   - rect: elemanın point dikdörtgeni (döndürmesiz), taşınmış yeriyle.
    static func liftingCovered(by movedIDs: Set<UUID>, in elements: [CanvasElement],
                               rect: (CanvasElement) -> CGRect) -> [CanvasElement] {
        var result = elements
        let boxIDs = elements.filter { movedIDs.contains($0.id) && $0.type == .box && !$0.isPinned }.map(\.id)
        for boxID in boxIDs {
            guard let boxIndex = result.firstIndex(where: { $0.id == boxID }) else { continue }
            let area = rect(result[boxIndex]).insetBy(dx: -tolerance, dy: -tolerance)
            let covered = result[..<boxIndex].filter { element in
                guard !element.isPinned, !movedIDs.contains(element.id) else { return false }
                return area.contains(SnapGuides.boundingBox(rect(element), degrees: element.properties.rotation ?? 0))
            }
            guard !covered.isEmpty else { continue }
            let coveredIDs = Set(covered.map(\.id))
            result.removeAll { coveredIDs.contains($0.id) }
            guard let newIndex = result.firstIndex(where: { $0.id == boxID }) else { continue }
            result.insert(contentsOf: covered, at: newIndex + 1)
        }
        return result
    }
}
