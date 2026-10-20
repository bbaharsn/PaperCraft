//
//  EditorViewModel.swift
//  PaperCraft
//

import Foundation
import Observation

/// Editördeki ekranı ve seçimi tutar; elemanları değiştiren tüm işlemler buradan geçer.
@Observable
final class EditorViewModel {
    /// Hangi bileşenlerin eklenebileceğini bilen katalog (sadece okunur).
    let catalog: ComponentCatalog
    /// İkon seçerken gösterilecek SF Symbol'ler (sadece okunur).
    let symbolCatalog: SymbolCatalog
    var screen: PrototypeScreen
    var selectedElementID: UUID?

    init(catalog: ComponentCatalog, symbolCatalog: SymbolCatalog = .empty, screen: PrototypeScreen) {
        self.catalog = catalog
        self.symbolCatalog = symbolCatalog
        self.screen = screen
    }

    /// Şu an seçili olan eleman; seçim yoksa `nil`.
    var selectedElement: CanvasElement? {
        screen.elements.first { $0.id == selectedElementID }
    }

    /// Bir elemanı seçer; `nil` verilirse seçimi kaldırır.
    func select(_ id: UUID?) {
        selectedElementID = id
    }

    /// Katalogdaki varsayılanlarla yeni bir eleman ekler ve onu seçer.
    /// Tür katalogda yoksa hiçbir şey yapmaz.
    func addElement(of type: ElementType) {
        guard let element = catalog.makeElement(of: type) else { return }
        screen.elements.append(element)   // sona eklenen en üstte çizilir
        selectedElementID = element.id
    }

    /// Seçili elemanı siler ve seçimi kaldırır. Seçili eleman yoksa hiçbir şey yapmaz.
    func deleteSelectedElement() {
        guard let id = selectedElementID else { return }
        screen.elements.removeAll { $0.id == id }
        selectedElementID = nil
    }

    /// Seçili elemanın özelliklerini değiştirir. Seçili eleman yoksa hiçbir şey yapmaz.
    /// Kullanım: `updateSelectedProperties { $0.text = "Giriş Yap" }`
    func updateSelectedProperties(_ change: (inout ElementProperties) -> Void) {
        guard let index = screen.elements.firstIndex(where: { $0.id == selectedElementID }) else { return }
        change(&screen.elements[index].properties)
    }

    /// Elemanı normalize miktarda (0...1) kaydırır; ekranın dışına taşmasını engeller.
    func moveElement(_ id: UUID, dx: Double, dy: Double) {
        guard let index = screen.elements.firstIndex(where: { $0.id == id }) else { return }

        var frame = screen.elements[index].frame
        frame.x = min(max(frame.x + dx, 0), 1 - frame.width)
        frame.y = min(max(frame.y + dy, 0), 1 - frame.height)
        screen.elements[index].frame = frame
    }
}
