//
//  ScreenChange.swift
//  PaperCraft
//

import Foundation

/// İki ekran hali arasında neyin değiştiğini kısa bir anahtarla anlatır.
/// Geri al, art arda gelen değişiklikleri sadece anahtarları aynıysa tek adım sayar:
/// köşe çekmek ya da yazı yazmak birleşir; yükseklik, şekil ve renk ayrı adımlar olur.
enum ScreenChange {
    /// Ör. "<id>|frame", "<id>|fillColor", "background". Eleman eklenip silindiyse ya da
    /// birden fazla eleman değiştiyse `nil` (hiçbir şeyle birleşmez).
    static func key(from old: PrototypeScreen, to new: PrototypeScreen) -> String? {
        let oldByID = Dictionary(old.elements.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let newByID = Dictionary(new.elements.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        guard Set(oldByID.keys) == Set(newByID.keys) else { return nil }

        let changed = new.elements.filter { oldByID[$0.id] != $0 }
        var parts: [String] = []
        if old.background != new.background {
            parts.append("background")
        }
        if old.name != new.name {
            parts.append("name")
        }
        guard changed.count <= 1 else { return nil }
        if let element = changed.first, let before = oldByID[element.id] {
            parts.append("\(element.id)|" + changedFields(before, element).joined(separator: ","))
        }
        return parts.isEmpty ? nil : parts.joined(separator: ";")
    }

    /// Elemanın değişen alanlarının adları; özelliklerde (`properties`) tek tek alan adına iner.
    private static func changedFields(_ old: CanvasElement, _ new: CanvasElement) -> [String] {
        var fields: [String] = []
        if old.type != new.type { fields.append("type") }
        if old.frame != new.frame { fields.append("frame") }
        if old.properties != new.properties {
            fields += differingLabels(old.properties, new.properties)
        }
        return fields
    }

    /// Aynı türden iki değerin farklı olan alt alanları (Mirror ile, alan adlarına göre).
    private static func differingLabels<T>(_ old: T, _ new: T) -> [String] {
        let oldChildren = Mirror(reflecting: old).children
        let newChildren = Array(Mirror(reflecting: new).children)
        return zip(oldChildren, newChildren).compactMap { oldChild, newChild in
            guard String(describing: oldChild.value) != String(describing: newChild.value) else { return nil }
            return oldChild.label ?? "?"
        }
    }
}
