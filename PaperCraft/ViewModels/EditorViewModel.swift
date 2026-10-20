//
//  EditorViewModel.swift
//  PaperCraft
//

import CoreGraphics
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

    // MARK: - Boyut

    /// Referans ekranın boyutu (point). Boyut işlemleri point ile yapılır,
    /// çünkü "200 × 50" gibi değerler kullanıcıya point olarak gösterilir.
    private var canvasSize: CGSize {
        CGSize(width: catalog.referenceCanvas.width, height: catalog.referenceCanvas.height)
    }

    /// Elemanın referans ekrandaki konumu ve boyutu (point).
    func pointRect(of element: CanvasElement) -> CGRect {
        CGRect(x: element.frame.x * canvasSize.width,
               y: element.frame.y * canvasSize.height,
               width: element.frame.width * canvasSize.width,
               height: element.frame.height * canvasSize.height)
    }

    /// Elemanı bir köşesinden çekerek büyütür/küçültür; karşı köşe yerinde kalır.
    /// `delta` parmağın son hareketidir (point). Eleman en küçük boyutun altına inmez,
    /// ekrandan taşmaz; daire buton hep kare kalır.
    func resizeElement(_ id: UUID, from corner: ResizeCorner, by delta: CGSize) {
        guard let index = screen.elements.firstIndex(where: { $0.id == id }) else { return }
        let element = screen.elements[index]
        let rect = pointRect(of: element)
        let minSize = minimumSize(of: element.type)

        var left = rect.minX, right = rect.maxX, top = rect.minY, bottom = rect.maxY
        if corner.isLeading {
            left = min(max(left + delta.width, 0), right - minSize.width)
        } else {
            right = max(min(right + delta.width, canvasSize.width), left + minSize.width)
        }
        if corner.isTop {
            top = min(max(top + delta.height, 0), bottom - minSize.height)
        } else {
            bottom = max(min(bottom + delta.height, canvasSize.height), top + minSize.height)
        }

        var newRect = CGRect(x: left, y: top, width: right - left, height: bottom - top)
        if isCircleButton(element) {
            newRect = squared(newRect, anchoredOppositeOf: corner)
        }
        setPointRect(newRect, at: index)
    }

    /// Özellikler sayfasından boyut girildiğinde çağrılır; sol üst köşe yerinde kalır.
    func setSelectedSize(width: Double, height: Double) {
        guard let index = screen.elements.firstIndex(where: { $0.id == selectedElementID }) else { return }
        let element = screen.elements[index]
        let rect = pointRect(of: element)
        let minSize = minimumSize(of: element.type)

        var newWidth = min(max(width, minSize.width), canvasSize.width - rect.minX)
        var newHeight = min(max(height, minSize.height), canvasSize.height - rect.minY)
        if isCircleButton(element) {
            // Hangisi değiştiyse onu esas al, diğerini ona eşitle.
            let side = newWidth != rect.width ? newWidth : newHeight
            newWidth = min(side, canvasSize.width - rect.minX, canvasSize.height - rect.minY)
            newHeight = newWidth
        }
        setPointRect(CGRect(x: rect.minX, y: rect.minY, width: newWidth, height: newHeight), at: index)
    }

    /// Seçili butonun şeklini değiştirir. Daireye geçerken çerçeve, ortası sabit kalarak kareye döner.
    func setSelectedButtonShape(_ shape: ButtonShape) {
        guard let index = screen.elements.firstIndex(where: { $0.id == selectedElementID }) else { return }
        screen.elements[index].properties.shape = shape

        guard shape == .circle else { return }
        let rect = pointRect(of: screen.elements[index])
        let side = min(rect.width, rect.height)
        setPointRect(CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side),
                     at: index)
    }

    private func setPointRect(_ rect: CGRect, at index: Int) {
        screen.elements[index].frame = NormalizedFrame(x: rect.minX / canvasSize.width,
                                                       y: rect.minY / canvasSize.height,
                                                       width: rect.width / canvasSize.width,
                                                       height: rect.height / canvasSize.height)
    }

    /// Katalogdaki en küçük boyut; katalogda yoksa Apple'ın önerdiği 44 pt dokunma alanı.
    private func minimumSize(of type: ElementType) -> CGSize {
        guard let minSize = catalog.definition(for: type)?.minSize else {
            return CGSize(width: 44, height: 44)
        }
        return CGSize(width: minSize.width, height: minSize.height)
    }

    private func isCircleButton(_ element: CanvasElement) -> Bool {
        element.type == .button && element.properties.shape == .circle
    }

    /// Dikdörtgeni, çekilen köşenin karşısındaki köşe sabit kalacak şekilde kareye çevirir.
    /// Kenar uzun olana göre seçilir ama ekrandan taşmayacak kadar kısaltılır.
    private func squared(_ rect: CGRect, anchoredOppositeOf corner: ResizeCorner) -> CGRect {
        let availableWidth = corner.isLeading ? rect.maxX : canvasSize.width - rect.minX
        let availableHeight = corner.isTop ? rect.maxY : canvasSize.height - rect.minY
        let side = min(max(rect.width, rect.height), availableWidth, availableHeight)

        let x = corner.isLeading ? rect.maxX - side : rect.minX
        let y = corner.isTop ? rect.maxY - side : rect.minY
        return CGRect(x: x, y: y, width: side, height: side)
    }
}
