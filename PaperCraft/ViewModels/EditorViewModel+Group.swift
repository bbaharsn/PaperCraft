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
        refreshMultiSelectionProperties()
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
        if updated != multiSelection {
            multiSelection = updated
            refreshMultiSelectionProperties()
        }
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
        // Kutu duran elemanların üstüne bırakıldıysa onları örtmesin, içine alsın (aynı geri al adımında)
        screen.elements = BoxContents.liftingCovered(by: ids, in: elements, rect: pointRect(of:))
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

    /// Seçili kutunun içindekiler (kutunun kendisi hariç); seçili eleman kutu değilse boş.
    private var selectedBoxContents: Set<UUID> {
        guard let box = selectedElement, box.type == .box else { return [] }
        return movingGroup(for: [box.id]).subtracting([box.id])
    }

    /// "Kutuyu çöz" gösterilsin mi? Seçili eleman içinde en az bir eleman olan bir kutu olmalı.
    var canUngroupSelected: Bool {
        !selectedBoxContents.isEmpty
    }

    /// "Kutuyu çöz": "Kutuya al"ın tersi. Yalnızca seçili kutu silinir; içindekiler yerinde ve aynı sırada kalır
    /// (iç içe kutular da). Tek geri al adımıdır. Sonra toplu mod açılır ve içindekiler seçili gelir.
    func ungroupSelectedBox() {
        let contents = selectedBoxContents
        guard let boxID = selectedElementID, !contents.isEmpty else { return }
        screen.elements.removeAll { $0.id == boxID }
        selectedElementID = nil
        isMultiSelecting = true
        multiSelection = contents
        ungroupUndoHint = (screen, boxID)
    }

    /// Toplu boyutlandırma başlar: başlangıç hali saklanır, sürüklerken her şey ona göre hesaplanır.
    func beginMultiSelectionResize() {
        multiResizeStart = screen
    }

    /// Toplu seçimi (kutuların içindekiler dahil) bir köşesinden oranı koruyarak ölçekler.
    /// `translation` parmağın başlangıçtan beri toplam hareketi (sayfa point'i). Hiçbir eleman en küçük
    /// boyutunun altına inmez; yazılar ve kontroller de aynı oranda büyür. Sürükleme bitene kadar geri al'a yazılmaz.
    func resizeMultiSelection(from corner: ResizeCorner, by translation: CGSize) {
        guard let start = multiResizeStart else { return }
        let group = BoxContents.group(startingFrom: multiSelection, in: start.elements, rect: pointRect(of:))
        let members = start.elements.filter { group.contains($0.id) }
        guard !members.isEmpty else { return }

        let rect = members
            .map { SnapGuides.boundingBox(pointRect(of: $0), degrees: $0.properties.rotation ?? 0) }
            .reduce(CGRect.null) { $0.union($1) }
        // En küçük eleman sınırına gelince grup durur; zaten sınırın altındaysa büyümeye zorlanmaz.
        let minimumScale = min(1, members.map { member in
            let size = minimumSize(of: member), current = pointRect(of: member)
            return max(size.width / current.width, size.height / current.height)
        }.max() ?? 0)
        let scale = GroupResize.scale(dragging: corner, by: translation, rect: rect,
                                      canvasWidth: canvasSize.width, minimumScale: minimumScale)
        let anchor = GroupResize.anchor(of: corner, in: rect)

        var elements = start.elements
        for index in elements.indices where group.contains(elements[index].id) {
            let scaled = GroupResize.scaled(pointRect(of: elements[index]), by: scale, around: anchor)
            elements[index].frame = NormalizedFrame(x: scaled.minX / canvasSize.width,
                                                    y: scaled.minY / canvasSize.height,
                                                    width: scaled.width / canvasSize.width,
                                                    height: scaled.height / canvasSize.height)
            if elements[index].type.scalesContentWithFrame {
                elements[index].properties.scaleContent(by: scale)
            }
        }
        withoutRecording { screen.elements = elements }
    }

    /// Toplu boyutlandırma biter: bütün sürükleme tek geri al adımı olarak yazılır.
    func endMultiSelectionResize() {
        guard let start = multiResizeStart else { return }
        multiResizeStart = nil
        let final = screen
        guard final != start else { return }
        withoutRecording { screen = start }
        screen = final
    }

    /// Toplu seçimdeki her şeyi (kutuların içindekiler dahil) tek geri al adımında siler.
    func deleteMultiSelection() {
        let doomed = movingGroup(for: multiSelection)
        guard !doomed.isEmpty else { return }
        screen.elements.removeAll { doomed.contains($0.id) }
        multiSelection = []
    }
}
