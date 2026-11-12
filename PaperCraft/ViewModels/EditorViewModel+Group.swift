//
//  EditorViewModel+Group.swift
//  PaperCraft
//

import CoreGraphics
import Foundation

/// Toplu seçim ve birlikte taşınan elemanlar (kutu + içindekiler, toplu seçim).
/// Tasarım: `docs/superpowers/specs/2026-11-11-multi-select-design.md`.
extension EditorViewModel {
    /// Toplu seçim modunu açar ya da kapatır; her iki durumda da seçim temizlenir.
    func toggleMultiSelectMode() {
        isMultiSelecting.toggle()
        selectedElementID = nil
        multiSelection = []
    }

    /// Toplu seçimde elemanı seçime ekler ya da çıkarır. Sabit barlar eklenmez; çizim sırası değişmez.
    func toggleInMultiSelection(_ id: UUID) {
        guard let element = screen.elements.first(where: { $0.id == id }), !element.isPinned else { return }
        if multiSelection.contains(id) {
            multiSelection.remove(id)
        } else {
            multiSelection.insert(id)
        }
    }

    func clearMultiSelection() {
        multiSelection = []
    }

    /// Seçim çerçevesi çizilirken seçimi günceller: çerçeve başlamadan önceki seçim (`base`) korunur,
    /// çerçevenin tamamen içine giren elemanlar eklenir. Çerçeve küçülünce çıkan eleman seçimden düşer.
    /// - Parameter marquee: sayfa point'iyle çerçeve.
    func selectInMarquee(_ marquee: CGRect, adding base: Set<UUID>) {
        let hits = MarqueeSelection.ids(in: marquee, elements: screen.elements, rect: pointRect(of:))
        let updated = base.union(hits)
        if updated != multiSelection { multiSelection = updated }
    }

    /// Verilen elemanlar taşınınca birlikte gelecek olanlar: kendileri ve içlerindeki kutuların içindekiler.
    /// Sabit barlar gruba girmez.
    func movingGroup(for ids: Set<UUID>) -> Set<UUID> {
        BoxContents.group(startingFrom: ids, in: screen.elements, rect: pointRect(of:))
    }

    /// Kümedeki elemanları kendi aralarındaki sırayı koruyarak en üste çıkarır. Geri al adımı sayılmaz.
    func bringToFront(_ ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        let front = screen.elements.filter { ids.contains($0.id) }
        let rest = screen.elements.filter { !ids.contains($0.id) }
        guard rest + front != screen.elements else { return }
        withoutRecording { screen.elements = rest + front }
    }

    /// Elemanları aynı miktarda (normalize) kaydırır; grup tek parça sınırlanır, aradaki boşluklar korunur.
    /// Tek atamayla yazılır, bu yüzden tek geri al adımıdır. Kümede sabit bar varsa ekranın içinde kalır.
    func moveGroup(_ ids: Set<UUID>, dx: Double, dy: Double) {
        let members = screen.elements.filter { ids.contains($0.id) }
        guard !members.isEmpty else { return }
        let move = GroupMove.clamped(dx: dx, dy: dy, frames: members.map(\.frame),
                                     keepsOnScreen: members.contains(where: \.isPinned))
        var elements = screen.elements
        for index in elements.indices where ids.contains(elements[index].id) {
            elements[index].frame.x += move.dx
            elements[index].frame.y += move.dy
        }
        screen.elements = elements
    }

    /// "Kutuya al": toplu seçimi (kutuların içindekiler dahil) kenarlarında pay bırakarak saran beyaz bir Kutu ekler.
    /// Kutu seçilenlerin hemen arkasına konur, seçilenler en üste çıkar; böylece hepsi kutunun içindekiler sayılır
    /// ve kutuyla birlikte taşınır. Tek geri al adımıdır. Sonra toplu mod kapanır ve yeni kutu seçilir.
    @discardableResult
    func wrapMultiSelectionInBox(padding: CGFloat = 16) -> UUID? {
        let group = movingGroup(for: multiSelection)
        let members = screen.elements.filter { group.contains($0.id) }
        guard !members.isEmpty, var box = catalog.makeElement(of: .box) else { return nil }

        let union = members
            .map { SnapGuides.boundingBox(pointRect(of: $0), degrees: $0.properties.rotation ?? 0) }
            .reduce(CGRect.null) { $0.union($1) }
            .insetBy(dx: -padding, dy: -padding)
        // Sayfanın yanlarından ve üstünden taşmasın
        let minX = max(union.minX, 0), maxX = min(union.maxX, canvasSize.width), minY = max(union.minY, 0)
        box.frame = NormalizedFrame(x: minX / canvasSize.width, y: minY / canvasSize.height,
                                    width: (maxX - minX) / canvasSize.width,
                                    height: (union.maxY - minY) / canvasSize.height)
        box.properties.fillColor = "#FFFFFF"

        let rest = screen.elements.filter { !group.contains($0.id) }
        screen.elements = rest + [box] + members
        isMultiSelecting = false
        multiSelection = []
        selectedElementID = box.id
        return box.id
    }

    /// Toplu seçimdeki her şeyi (kutuların içindekiler dahil) tek geri al adımında siler.
    func deleteMultiSelection() {
        let doomed = movingGroup(for: multiSelection)
        guard !doomed.isEmpty else { return }
        screen.elements.removeAll { doomed.contains($0.id) }
        multiSelection = []
    }
}
