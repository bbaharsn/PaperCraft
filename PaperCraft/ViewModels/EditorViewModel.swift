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
    /// Görsel seçerken gösterilecek hazır görseller (sadece okunur).
    let imageLibrary: ImageLibrary
    var screen: PrototypeScreen
    var selectedElementID: UUID?

    init(catalog: ComponentCatalog, symbolCatalog: SymbolCatalog = .empty,
         imageLibrary: ImageLibrary = .empty, screen: PrototypeScreen) {
        self.catalog = catalog
        self.symbolCatalog = symbolCatalog
        self.imageLibrary = imageLibrary
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
        let minSize = minimumSize(of: element)

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
        let minSize = minimumSize(of: element)

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

    // MARK: - Üst bar

    /// Seçili üst barın başlık türünü değiştirir; bar yeni türün yüksekliğine uzar ya da kısalır.
    /// Başlığın yeri de o türün alışılmış yerine döner (küçük: ortada, büyük: sol altta).
    /// Üst kenar yerinde kalır.
    func setSelectedNavigationTitleMode(_ mode: NavigationTitleMode) {
        guard let index = screen.elements.firstIndex(where: { $0.id == selectedElementID }),
              screen.elements[index].type == .navigationBar else { return }
        screen.elements[index].properties.titleDisplayMode = mode
        screen.elements[index].properties.textAlignment = mode.defaultAlignment
        screen.elements[index].properties.verticalAlignment = mode.defaultVerticalAlignment

        var rect = pointRect(of: screen.elements[index])
        rect.size.height = mode.barHeight
        setPointRect(rect, at: index)
    }

    // MARK: - Alt menü

    /// Seçili alt menünün sonuna yeni bir sekme ekler. Sekme sayısı üst sınırdaysa hiçbir şey yapmaz.
    func addSelectedTab() {
        updateSelectedTabItems { items, _ in
            guard items.count < TabItem.allowedCount.upperBound else { return }
            items.append(TabItem(text: "Tab \(items.count + 1)", symbolName: "star"))
        }
    }

    /// Seçili alt menüden bir sekmeyi siler; alt sınırın altına inmez.
    /// Seçili sekme silinirse yanındaki seçili olur, seçim hep aynı sekmede kalır.
    func removeSelectedTab(at index: Int) {
        updateSelectedTabItems { items, selectedIndex in
            guard items.count > TabItem.allowedCount.lowerBound, items.indices.contains(index) else { return }
            items.remove(at: index)
            if index < selectedIndex {
                selectedIndex -= 1
            }
            selectedIndex = min(selectedIndex, items.count - 1)
        }
    }

    /// Seçili alt menüdeki bir sekmenin yazısını ya da ikonunu değiştirir.
    /// Kullanım: `updateSelectedTab(at: 0) { $0.text = "Ana Sayfa" }`
    func updateSelectedTab(at index: Int, _ change: (inout TabItem) -> Void) {
        updateSelectedTabItems { items, _ in
            guard items.indices.contains(index) else { return }
            change(&items[index])
        }
    }

    /// Seçili eleman alt menüyse sekmelerini ve seçili sekmeyi birlikte değiştirir.
    private func updateSelectedTabItems(_ change: (inout [TabItem], inout Int) -> Void) {
        guard selectedElement?.type == .tabBar else { return }
        updateSelectedProperties { properties in
            var items = properties.items ?? []
            var selectedIndex = properties.selectedIndex ?? 0
            change(&items, &selectedIndex)
            properties.items = items
            properties.selectedIndex = selectedIndex
        }
    }

    // MARK: - Kaydırıcı

    /// Seçili kaydırıcının yan ikonlarını açar/kapatır.
    /// Çerçeve ikonlar kadar genişler ya da daralır; çubuğun kendi uzunluğu değişmez.
    func setSelectedSliderShowsSideIcons(_ isOn: Bool) {
        changeSliderParts { $0.showsSideIcons = isOn }
    }

    /// Seçili kaydırıcının değer yazısını açar/kapatır; çerçeve yazı kadar genişler ya da daralır.
    func setSelectedSliderShowsValue(_ isOn: Bool) {
        changeSliderParts { $0.showsValue = isOn }
    }

    /// Seçili kaydırıcının aralığını değiştirir. Alt sınır üst sınırdan küçük kalır
    /// (eşit ya da büyük girilirse diğeri bir fazlası/eksiği olur); değer aralığın içine çekilir.
    func setSelectedSliderRange(min lower: Double, max upper: Double) {
        updateSelectedProperties { properties in
            let changedLower = lower != properties.sliderRange.lowerBound
            if lower >= upper {
                properties.minValue = changedLower ? lower : upper - 1
                properties.maxValue = changedLower ? lower + 1 : upper
            } else {
                properties.minValue = lower
                properties.maxValue = upper
            }
            properties.value = properties.sliderValue
        }
    }

    /// Kaydırıcının bir parçasını açıp kapatır ve aradaki genişlik farkını çerçeveye ekler.
    /// Sol kenar yerinde kalır; ekrandan taşacaksa eleman sola kayar.
    private func changeSliderParts(_ change: (inout ElementProperties) -> Void) {
        guard let index = screen.elements.firstIndex(where: { $0.id == selectedElementID }),
              screen.elements[index].type == .slider else { return }

        let oldExtra = SliderLayout.extraWidth(for: screen.elements[index].properties)
        change(&screen.elements[index].properties)
        let newExtra = SliderLayout.extraWidth(for: screen.elements[index].properties)

        let element = screen.elements[index]
        var rect = pointRect(of: element)
        rect.size.width = min(max(rect.width + newExtra - oldExtra, minimumSize(of: element).width),
                              canvasSize.width)
        rect.origin.x = min(rect.minX, canvasSize.width - rect.width)
        setPointRect(rect, at: index)
    }

    private func setPointRect(_ rect: CGRect, at index: Int) {
        screen.elements[index].frame = NormalizedFrame(x: rect.minX / canvasSize.width,
                                                       y: rect.minY / canvasSize.height,
                                                       width: rect.width / canvasSize.width,
                                                       height: rect.height / canvasSize.height)
    }

    /// Katalogdaki en küçük boyut; katalogda yoksa Apple'ın önerdiği 44 pt dokunma alanı.
    /// Kaydırıcıda açık ikon/değer yazısı varsa onlar da eklenir, çubuk ezilmesin.
    /// Büyük başlıklı üst bar, başlığı sığacak kadar yüksek kalır.
    private func minimumSize(of element: CanvasElement) -> CGSize {
        guard let minSize = catalog.definition(for: element.type)?.minSize else {
            return CGSize(width: 44, height: 44)
        }
        let extra = element.type == .slider ? SliderLayout.extraWidth(for: element.properties) : 0
        var height = minSize.height
        if element.type == .navigationBar, let mode = element.properties.titleDisplayMode {
            height = max(height, mode.barHeight)
        }
        return CGSize(width: minSize.width + extra, height: height)
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
