//
//  CanvasView.swift
//  PaperCraft
//

import SwiftUI

/// Bir ekranın elemanlarını, kağıt görünümlü bir tuval üzerinde gerçek konumlarına yerleştirir.
/// Elemanlar dokunarak seçilir ve sürüklenerek taşınır.
///
/// Tuval her zaman gerçek iPhone boyutunda (393×852) çizilir, sonra ekrana sığacak kadar
/// küçültülür. Böylece yazılar dahil her şey orantılı küçülür.
struct CanvasView: View {
    let viewModel: EditorViewModel
    /// Bir elemana çift dokunulunca ya da basılı tutulunca (seçildikten sonra) çağrılır; ör. Özellikler sayfasını açmak için.
    var onDoubleTap: () -> Void = {}
    /// Sayfada boş bir yere çift dokunulunca çağrılır; ör. arka plan ayarlarını açmak için.
    var onBackgroundDoubleTap: () -> Void = {}
    /// Sayfada boş bir yere dokunulunca çağrılır (seçim zaten kalkar); ör. kataloğu kapatmak için.
    var onBackgroundTap: () -> Void = {}
    /// Alttan bir sayfanın kapattığı yükseklik (point). Tuval küçülmez; seçili eleman
    /// bu alanın altında kalacaksa tuval o eleman görünene kadar yukarı kayar.
    var bottomInset: CGFloat = 0
    /// Kartın ekrandaki yeri değişince çağrılır; önizleme buradan büyür.
    var onCardFrameChange: (CGRect) -> Void = { _ in }
    /// Ekran noktası → sayfa noktası eşlemesi değişince çağrılır; katalogdan sürüklenen eleman buna göre bırakılır.
    var onMappingChange: (CanvasMapping) -> Void = { _ in }

    /// Şu an birlikte sürüklenen elemanlar (kutu + içindekiler ya da toplu seçim) ve parmağın ne kadar
    /// kaydığı (tuvalin kendi point'leri). Sürükleme bitene kadar model değişmez; sadece görüntü kayar.
    @State private var draggingIDs: Set<UUID> = []
    @State private var dragOffset: CGSize = .zero
    /// Sürüklenen eleman şu an hangi hizalara yapışık; çizgiler bunlardan çizilir.
    @State private var snapGuides: [SnapGuide] = []

    /// İki parmakla yakınlaştırma ve kaydırma durumu.
    @State private var viewport = CanvasViewport()
    /// Tek parmakla boş yerde kaydırma başladığındaki durum; hareket buna göre hesaplanır.
    @State private var gestureStart: CanvasViewport?

    /// İki parmaklı hareket (yakınlaştırma ve/veya kaydırma). İkisi aynı anda olabilir; ikisi de
    /// `twoFingerStart`'tan hesaplanır. Biri ortada başlarsa başlangıç o anki duruma taşınır (`magBase`, `panBase`).
    @State private var twoFingerStart: CanvasViewport?
    @State private var isMagnifying = false
    @State private var isTwoFingerPanning = false
    @State private var pinchMagnification: CGFloat = 1
    @State private var pinchAnchor: CGPoint = .zero
    @State private var twoFingerTranslation: CGSize = .zero
    @State private var magBase: CGFloat = 1
    @State private var panBase: CGSize = .zero
    /// İki parmak gelince yarıda kesilen tek parmaklı hareket, parmak kalkana kadar yeniden başlamasın.
    @State private var oneFingerCancelled = false
    /// İki parmak ekrandayken eleman taşınmasın, çerçeve çizilmesin.
    private var isPinching: Bool { isMagnifying || isTwoFingerPanning }

    /// Toplu seçimde boş yerden çizilen seçim çerçevesi: başladığı nokta (sayfa point'i), parmağın
    /// son yeri (ekran point'i) ve çerçeve başlamadan önceki seçim.
    @State private var marqueeStart: CGPoint?
    @State private var marqueeFinger: CGPoint = .zero
    @State private var marqueeBase: Set<UUID> = []
    /// Seçimi saran çerçevenin boş bir yerinden tutulup taşınan grubun öncü elemanı.
    @State private var groupDragLead: CanvasElement?

    /// Kartın ve canvas alanının ekrandaki yeri; sürüklenen eleman kenara gelince sayfayı kaydırmak için.
    @State private var cardFrame: CGRect = .zero
    @State private var areaFrame: CGRect = .zero
    /// Sürükleme sırasında kenarda otomatik kaydırmanın hızı (tuval point'i / adım); 0 ise durur.
    @State private var edgeScrollSpeed: CGFloat = 0
    /// Bu sürüklemede otomatik kaydırmayla kat edilen yol (tuval point'i); eleman bu kadar daha kayar.
    @State private var edgeScrolled: CGFloat = 0
    @State private var edgeScrollTask: Task<Void, Never>?

    /// Elemana bu kadar (saniye) basılı tutunca Özellikler açılır.
    private static let longPressDuration: Double = 0.5
    /// Kartın üst/alt kenarından bu kadar içeride (ekran point'i) parmak sayfayı kaydırmaya başlar.
    private static let edgeBand: CGFloat = 48
    /// En hızlı otomatik kaydırma, adım başına (tuval point'i; saniyede ~60 adım).
    private static let maxEdgeSpeed: CGFloat = 12

    /// Referans iPhone ekranı (point). Normalize koordinatlar buna göredir; önizleme de aynısını kullanır.
    static let referenceSize = CanvasMapping.referenceSize
    private let referenceSize = Self.referenceSize

    var body: some View {
        GeometryReader { geometry in
            let available = geometry.size
            let fitted = fittedScale(in: available)
            // Kartın alana tam sığdığı boyut; yakınlaştırma bunun katıdır.
            let fittedCard = CGSize(width: referenceSize.width * fitted, height: referenceSize.height * fitted)
            let scale = fitted * viewport.zoom

            card(scale: scale)
                // Büyüyen kart alanın ortasında kalır, taşan kısmı kenarlardan dışarı çıkar.
                .frame(width: available.width, height: available.height)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { areaFrame = $0 }
                // Büyütülmüş kart üst barın ve saatin arkasına taşmasın (editörün 16 pt kenar boşluğu dahil).
                .clipShape(Rectangle().inset(by: -16))
                .contentShape(Rectangle())
                // Elemanların kendi taşıma hareketi önce gelir; boş yerde sürüklemek sayfayı (büyütülmüşse önce kartı) kaydırır.
                .gesture(panGesture(cardSize: fittedCard, available: available, scale: scale))
                .simultaneousGesture(pinchGesture(cardSize: fittedCard, available: available, fitted: fitted))
                #if os(iOS)
                .background {
                    TwoFingerPan { translation in
                        if !isTwoFingerPanning {
                            if !isPinching { cancelOneFingerGestures() }
                            isTwoFingerPanning = true
                            if !isMagnifying { pinchMagnification = 1 }
                            twoFingerStart = viewport
                            magBase = pinchMagnification
                            panBase = .zero
                        }
                        twoFingerTranslation = translation
                        updateTwoFinger(cardSize: fittedCard, available: available, fitted: fitted)
                    } onEnded: {
                        isTwoFingerPanning = false
                        finishTwoFingerIfDone()
                    }
                }
                #endif
                .overlay(alignment: .topTrailing) {
                    if viewport.isZoomed { zoomBadge }
                }
                // Özellikler sayfası açılınca ya da başka eleman seçilince, seçili eleman sayfanın altında kalmasın.
                .onChange(of: bottomInset) { revealSelection(in: available, scale: scale) }
                .onChange(of: viewModel.selectedElementID) { revealSelection(in: available, scale: scale) }
        }
        // Katalogdan eklenen eleman o an görünen alana gelsin
        .onChange(of: viewport.scroll, initial: true) { _, scroll in
            viewModel.visibleTop = scroll / referenceSize.height
            // Çerçeve çizerken sayfa kenarda kendiliğinden kayınca çerçeve de uzar
            updateMarqueeSelection()
        }
        .onChange(of: CanvasMapping(area: areaFrame, viewport: viewport), initial: true) { _, mapping in
            onMappingChange(mapping)
        }
        // Eleman silinince sayfa kısalır; kaydırma yeni sınırın dışında kalmasın
        .onChange(of: contentHeight) { _, height in
            let limit = CanvasViewport.maxScroll(contentHeight: height)
            if viewport.scroll > limit {
                withAnimation(.snappy) { viewport.scroll = limit }
            }
        }
    }

    /// Sayfanın gerçek uzunluğu (ekran yüksekliği birimi).
    private var contentHeight: Double { viewModel.screen.contentHeight }

    /// Kağıt kart: kayan sayfa (arka plan, elemanlar, sayfa sonu) ve üstünde sabit barlar.
    /// Yakınlaştırma ve kaydırma uygulanmış halde.
    private func card(scale: CGFloat) -> some View {
        // Kaydırılabilecek en alt noktaya kadar çizilir: sayfa + bir boş ekran.
        let scrollableHeight = CGFloat(contentHeight + 1) * referenceSize.height

        return ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                backgroundLayer(height: scrollableHeight)
                elementsLayer(scale: scale, pinned: false)
                    .frame(width: referenceSize.width, height: scrollableHeight)
                groupOutlineLayer(scale: scale)
                    .frame(width: referenceSize.width, height: scrollableHeight, alignment: .topLeading)
                if let rect = marqueeRect {
                    SelectionMarquee(rect: rect, scale: scale)
                        .frame(width: referenceSize.width, height: scrollableHeight, alignment: .topLeading)
                }
                if contentHeight > 1 {
                    PageEndLine(scale: scale)
                        .frame(width: referenceSize.width)
                        .offset(y: CGFloat(contentHeight) * referenceSize.height)
                }
            }
            .frame(width: referenceSize.width, height: scrollableHeight, alignment: .topLeading)
            // "Sayfa arka planıyla aynı" kutular gradyanın kendi yerine düşen parçasını çizer
            .pageBackdrop(viewModel.screen.background,
                          size: CGSize(width: referenceSize.width, height: CGFloat(contentHeight) * referenceSize.height))
            .offset(y: -viewport.scroll)

            // Sabit üst bar ve alt menü kaymaz; içerik altından geçer.
            elementsLayer(scale: scale, pinned: true)
                .frame(width: referenceSize.width, height: referenceSize.height)

            guidesLayer(scale: scale)
        }
        .frame(width: referenceSize.width, height: referenceSize.height, alignment: .topLeading)
                // Gerçek boyutta çizilen tuvali ekrana sığacak kadar küçült
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: referenceSize.width * scale,
                       height: referenceSize.height * scale,
                       alignment: .topLeading)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .paperCard()
                .overlay(alignment: .topLeading) { tape }
                .offset(x: viewport.pan.width, y: viewport.pan.height)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                    cardFrame = frame
                    onCardFrameChange(frame)
                }
    }

    /// Sayfanın arka planı ve boş yere dokunma alanı. Geçiş sayfanın gerçek uzunluğu boyunca yayılır (Dene'deki gibi);
    /// altındaki boşlukta geçişin en alt satırı aşağı uzatılır, böylece her yönde kesintisiz devam eder.
    private func backgroundLayer(height: CGFloat) -> some View {
        let background = ScreenBackgroundView(background: viewModel.screen.background)
        let gradientHeight = CGFloat(contentHeight) * referenceSize.height
        let extra = max(height - gradientHeight, 1)

        return VStack(spacing: 0) {
            background.frame(height: gradientHeight)
            Color.clear
                .frame(height: extra)
                .overlay(alignment: .top) {
                    background
                        .frame(height: gradientHeight)
                        .frame(height: 1, alignment: .bottom)
                        .clipped()
                        .scaleEffect(x: 1, y: extra, anchor: .top)
                }
        }
        .frame(width: referenceSize.width, height: height)
        // Dokunuşlar arka planın üstünde; elemana dokunmak buraya gelmez.
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            guard !viewModel.isMultiSelecting else { return }
            onBackgroundDoubleTap()
        }
        // Tek dokunuş beklemeden hemen seçimi kaldırsın diye çift dokunuşla aynı anda dinlenir.
        // Toplu seçimde mod açık kalır, sadece seçim temizlenir.
        .simultaneousGesture(TapGesture().onEnded {
            if viewModel.isMultiSelecting {
                viewModel.clearMultiSelection()
            } else {
                viewModel.select(nil)
            }
            onBackgroundTap()
        })
        // Toplu seçimde boş yerden sürüklemek seçim çerçevesi çizer (sayfayı iki parmakla kaydırmak serbest).
        .gesture(marqueeGesture, including: viewModel.isMultiSelecting ? .all : .none)
    }

    /// Seçim çerçevesi: başlangıçtan parmağın şu anki yerine (sayfa point'i). Çizilmiyorsa nil.
    private var marqueeRect: CGRect? {
        guard let start = marqueeStart else { return nil }
        let end = pagePoint(fromGlobal: marqueeFinger)
        return CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                      width: abs(end.x - start.x), height: abs(end.y - start.y))
    }

    /// Ekran noktası → kayan sayfadaki nokta (tuval point'i, kaydırma dahil).
    private func pagePoint(fromGlobal point: CGPoint) -> CGPoint {
        let scale = cardFrame.width / referenceSize.width
        guard scale > 0 else { return .zero }
        return CGPoint(x: (point.x - cardFrame.minX) / scale,
                       y: (point.y - cardFrame.minY) / scale + viewport.scroll)
    }

    private var marqueeGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                guard !isPinching, !oneFingerCancelled else { return }
                let scale = cardFrame.width / referenceSize.width
                // Seçimi saran çerçevenin içinden tutulduysa çerçeve çizilmez, bütün seçim taşınır
                if let lead = groupDragLead {
                    dragChanged(lead: lead, translation: value.translation, fingerY: value.location.y, scale: scale)
                    return
                }
                if marqueeStart == nil {
                    let start = pagePoint(fromGlobal: value.startLocation)
                    if let rect = multiSelectionRect, rect.contains(start),
                       let lead = viewModel.screen.elements.first(where: {
                           viewModel.multiSelection.contains($0.id) && !$0.isPinned
                       }) {
                        groupDragLead = lead
                        dragChanged(lead: lead, translation: value.translation, fingerY: value.location.y, scale: scale)
                        return
                    }
                    marqueeStart = start
                    marqueeBase = viewModel.multiSelection
                }
                marqueeFinger = value.location
                updateMarqueeSelection()
                updateEdgeScroll(fingerY: value.location.y)
            }
            .onEnded { value in
                if let lead = groupDragLead {
                    dragEnded(lead: lead, translation: value.translation,
                              scale: cardFrame.width / referenceSize.width)
                    groupDragLead = nil
                }
                stopEdgeScroll()
                edgeScrolled = 0
                marqueeStart = nil
                oneFingerCancelled = false
            }
    }

    private func updateMarqueeSelection() {
        guard let rect = marqueeRect else { return }
        viewModel.selectInMarquee(rect, adding: marqueeBase)
    }

    /// Yakınlaştırılmışken sağ üstte görünen oran; dokununca kart yeniden alana sığar (kaydırma yerinde kalır).
    private var zoomBadge: some View {
        Button {
            withAnimation(.snappy) { viewport = CanvasViewport(scroll: viewport.scroll) }
        } label: {
            Label("%\(Int((viewport.zoom * 100).rounded()))", systemImage: "arrow.down.right.and.arrow.up.left")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.paper)
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(Theme.ink.opacity(0.85), in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(8)
        .accessibilityLabel("Yakınlaştırmayı sıfırla")
    }

    /// İki parmakla yakınlaştırma (Mac'te trackpad'de kıstırma).
    private func pinchGesture(cardSize: CGSize, available: CGSize, fitted: CGFloat) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if !isMagnifying {
                    if !isPinching { cancelOneFingerGestures() }
                    isMagnifying = true
                    pinchMagnification = 1
                    pinchAnchor = CGPoint(x: value.startLocation.x - available.width / 2,
                                          y: value.startLocation.y - available.height / 2)
                    twoFingerStart = viewport
                    magBase = 1
                    panBase = isTwoFingerPanning ? twoFingerTranslation : .zero
                }
                pinchMagnification = value.magnification
                updateTwoFinger(cardSize: cardSize, available: available, fitted: fitted)
            }
            .onEnded { _ in
                isMagnifying = false
                finishTwoFingerIfDone()
            }
    }

    /// İki parmaklı hareketin o anki hali: önce yakınlaştırma (parmakların arası sabit kalır), sonra kaydırma.
    private func updateTwoFinger(cardSize: CGSize, available: CGSize, fitted: CGFloat) {
        guard let start = twoFingerStart else { return }
        let pinched = CanvasViewport.pinched(from: start, magnification: pinchMagnification / magBase,
                                             anchor: pinchAnchor, cardSize: cardSize, available: available)
        let move = CGSize(width: twoFingerTranslation.width - panBase.width,
                          height: twoFingerTranslation.height - panBase.height)
        viewport = .dragged(from: pinched, by: move, cardSize: cardSize, available: available,
                            scale: fitted * pinched.zoom, contentHeight: contentHeight)
    }

    /// İki parmak da kalkınca hareket biter; sığdığından küçükse kart yerine oturur.
    private func finishTwoFingerIfDone() {
        guard !isPinching else { return }
        twoFingerStart = nil
        twoFingerTranslation = .zero
        if !viewport.isZoomed {
            withAnimation(.snappy) { viewport = CanvasViewport(scroll: viewport.scroll) }
        }
    }

    /// İkinci parmak gelince tek parmaklı hareketler iptal olur: taşınan eleman yerine döner,
    /// çizilen çerçeve kaybolur ve seçim çerçeveden önceki haline döner.
    private func cancelOneFingerGestures() {
        if gestureStart != nil || marqueeStart != nil || !draggingIDs.isEmpty || groupDragLead != nil {
            oneFingerCancelled = true
        }
        gestureStart = nil
        groupDragLead = nil
        draggingIDs = []
        dragOffset = .zero
        snapGuides = []
        stopEdgeScroll()
        edgeScrolled = 0
        if marqueeStart != nil {
            viewModel.multiSelection = marqueeBase
            marqueeStart = nil
        }
    }

    /// Boş bir yerde sürükleyince sayfa kayar; büyütülmüşse önce kart kendi sınırına kadar kayar.
    private func panGesture(cardSize: CGSize, available: CGSize, scale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard !isPinching, !oneFingerCancelled else { return }
                if gestureStart == nil { gestureStart = viewport }
                guard let start = gestureStart else { return }
                viewport = .dragged(from: start, by: value.translation, cardSize: cardSize, available: available,
                                    scale: scale, contentHeight: contentHeight)
            }
            .onEnded { _ in
                gestureStart = nil
                oneFingerCancelled = false
            }
    }

    /// Seçili eleman alttaki sayfanın (Özellikler) altında kalacaksa sayfayı o eleman görünene kadar kaydırır.
    /// Kart yerinden oynamaz; böylece içerik üst barın arkasına kaymaz. Sabit barlar için bir şey yapılmaz.
    private func revealSelection(in available: CGSize, scale: CGFloat) {
        guard bottomInset > 0, let element = viewModel.selectedElement, !element.isPinned else { return }
        let margin: CGFloat = 16

        // Kart alanın ortasında (büyütülüp kaydırıldıysa o kadar ötesinde); elemanın ekrandaki üst ve alt kenarı
        let cardTop = (available.height - referenceSize.height * scale) / 2 + viewport.pan.height
        let elementTop = cardTop + (element.frame.y * referenceSize.height - viewport.scroll) * scale
        let elementBottom = elementTop + element.frame.height * referenceSize.height * scale

        let needed = elementBottom - (available.height - bottomInset - margin)
        // Eleman çok uzunsa üst kenarı kartın üstünden çıkacak kadar kaydırma
        let shift = min(needed, elementTop - max(cardTop, 0) - margin)
        guard shift > 0 else { return }
        let limit = CanvasViewport.maxScroll(contentHeight: contentHeight)
        withAnimation(.snappy) {
            viewport.scroll = min(viewport.scroll + shift / scale, limit)
        }
    }

    /// Elemanlar, gerçek iPhone point'leriyle yerleştirilmiş halde. `pinned` true ise sadece sabit barlar
    /// (kaymayan katman), false ise geri kalanlar (kayan sayfa). Sıra dizideki sıradır.
    private func elementsLayer(scale: CGFloat, pinned: Bool) -> some View {
        let layerElements = viewModel.screen.elements.enumerated().filter { $0.element.isPinned == pinned }
        return ZStack {
            ForEach(layerElements, id: \.element.id) { index, element in
                let frame = element.frame
                let isSelected = element.id == viewModel.selectedElementID && !viewModel.isMultiSelecting
                let isDashed = (draggingIDs.count > 1 && draggingIDs.contains(element.id))
                    || (viewModel.isMultiSelecting && viewModel.multiSelection.contains(element.id))

                ElementView(element: element)
                    .allowsHitTesting(false)
                    .frame(width: frame.width * referenceSize.width,
                           height: frame.height * referenceSize.height)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        guard !viewModel.isMultiSelecting else { return }
                        viewModel.select(element.id)
                        onDoubleTap()
                    }
                    // Tek dokunuş beklemeden hemen seçsin diye çift dokunuşla aynı anda dinlenir.
                    // Toplu seçimde dokunmak elemanı seçime ekler ya da çıkarır.
                    .simultaneousGesture(TapGesture().onEnded {
                        if viewModel.isMultiSelecting {
                            viewModel.toggleInMultiSelection(element.id)
                        } else {
                            viewModel.select(element.id)
                        }
                    })
                    // Basılı tutmak da çift dokunuş gibi Özellikler'i açar. Parmak kayarsa iptal olur, taşıma başlar.
                    .simultaneousGesture(LongPressGesture(minimumDuration: Self.longPressDuration).onEnded { _ in
                        guard draggingIDs.isEmpty, !isPinching, !viewModel.isMultiSelecting else { return }
                        viewModel.select(element.id)
                        onDoubleTap()
                    })
                    .gesture(dragGesture(for: element, scale: scale))
                    // Taşıma hareketinden sonra eklenir; böylece tutamaçlar kendi hareketini alır.
                    .overlay {
                        if isSelected {
                            SelectionOverlay(element: element, scale: scale,
                                             onResize: { corner, delta in
                                                 viewModel.resizeElement(element.id, from: corner, by: delta)
                                             },
                                             onRotate: element.type == .image || element.type == .symbol ? { degrees in
                                                 viewModel.setRotation(element.id,
                                                                       degrees: EditorViewModel.snappedRotation(degrees))
                                             } : nil)
                        } else if isDashed {
                            DashedOutline(scale: scale)
                        }
                    }
                    // Seçim çizgisi de elemanla birlikte döner
                    .rotationEffect(.degrees(element.properties.rotation ?? 0))
                    .offset(draggingIDs.contains(element.id)
                            ? CGSize(width: dragOffset.width, height: dragOffset.height + edgeScrolled)
                            : .zero)
                    .position(x: (frame.x + frame.width / 2) * referenceSize.width,
                              y: (frame.y + frame.height / 2) * referenceSize.height)
                    // ZStack sıra değişince çizim sırasını her zaman güncellemiyor; dizideki sırayı açıkça veriyoruz.
                    .zIndex(Double(index))
            }
        }
    }

    /// Toplu seçimdeki bütün elemanları saran ince çerçeve; seçim sürüklenirken onunla birlikte kayar.
    /// Sabit barlar toplu seçime girmediği için kayan sayfa katmanında çizilir.
    @ViewBuilder
    private func groupOutlineLayer(scale: CGFloat) -> some View {
        if let rect = multiSelectionRect {
            let isMoving = !draggingIDs.isEmpty && viewModel.multiSelection.isSubset(of: draggingIDs)
            GroupOutline(rect: rect, scale: scale)
                .offset(isMoving ? CGSize(width: dragOffset.width, height: dragOffset.height + edgeScrolled) : .zero)
                .allowsHitTesting(false)
        }
    }

    /// Toplu seçimdeki elemanları saran ortak kutu (sayfa point'i); seçim yoksa nil.
    private var multiSelectionRect: CGRect? {
        guard viewModel.isMultiSelecting else { return nil }
        return viewModel.screen.elements
            .filter { viewModel.multiSelection.contains($0.id) && !$0.isPinned }
            .map { SnapGuides.boundingBox(viewModel.pointRect(of: $0), degrees: $0.properties.rotation ?? 0) }
            .reduce(nil) { $0?.union($1) ?? $1 }
    }

    /// Kartın sol üstüne yapıştırılmış sarı bant.
    private var tape: some View {
        Rectangle()
            .fill(Theme.tape.opacity(0.9))
            .frame(width: 64, height: 18)
            .rotationEffect(.degrees(3))
            .offset(x: 56, y: -9)
            .allowsHitTesting(false)
    }

    /// Sürüklerken sadece görüntüyü kaydırır, bırakınca modeli günceller.
    /// Parmak ekran point'iyle hareket eder; tuval küçültüldüğü için `scale`'e böleriz.
    private func dragGesture(for element: CanvasElement, scale: CGFloat) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                guard !isPinching, !oneFingerCancelled else { return }
                dragChanged(lead: element, translation: value.translation, fingerY: value.location.y, scale: scale)
            }
            .onEnded { value in
                oneFingerCancelled = false
                dragEnded(lead: element, translation: value.translation, scale: scale)
            }
    }

    /// Sürükleme sürerken: ilk adımda taşınacakları belirler, sonra görüntüyü hizaya yapıştırarak kaydırır.
    /// `lead`, parmağın tuttuğu eleman (seçim çerçevesinin içinden tutulduysa seçimdeki ilk eleman).
    private func dragChanged(lead: CanvasElement, translation: CGSize, fingerY: CGFloat, scale: CGFloat) {
        if draggingIDs.isEmpty {
            startDrag(of: lead)
        }
        let snap = snapped(draggingIDs, lead: lead, translation: translation, scale: scale)
        dragOffset = snap.offset
        snapGuides = snap.guides
        if !lead.isPinned {
            updateEdgeScroll(fingerY: fingerY)
        }
    }

    /// Sürükleme bitince modeli tek seferde günceller (tek geri al adımı).
    private func dragEnded(lead: CanvasElement, translation: CGSize, scale: CGFloat) {
        stopEdgeScroll()
        snapGuides = []
        // Yakınlaştırma yüzünden iptal edildiyse eleman yerinde kalır
        guard draggingIDs.contains(lead.id) else { return }
        // Tuval point'i → normalize dönüşümü; kenarda kendiliğinden kayılan yol da eklenir
        let offset = snapped(draggingIDs, lead: lead, translation: translation, scale: scale).offset
        let dx = offset.width / referenceSize.width
        let dy = (offset.height + edgeScrolled) / referenceSize.height
        // Hizaya yapışıp eski yerine döndüyse boş bir geri al adımı oluşmasın
        if abs(dx) > 1e-6 || abs(dy) > 1e-6 {
            viewModel.moveGroup(draggingIDs, dx: dx, dy: dy)
        }
        draggingIDs = []
        dragOffset = .zero
        edgeScrolled = 0
    }

    /// Sürükleme başlarken birlikte taşınacak elemanları belirler.
    /// Normal modda: dokunulan eleman seçilir; kutuysa içindekiler de gelir.
    /// Toplu modda: seçili bir elemana dokunulduysa bütün seçim, değilse yalnız o eleman (kutuysa içindekilerle).
    /// Taşınanlar en üste çıkar; böylece grup başkalarının altına kaymaz, kutuya bırakılan eleman kutudan sonra gelir.
    private func startDrag(of element: CanvasElement) {
        if viewModel.isMultiSelecting {
            let start = viewModel.multiSelection.contains(element.id) ? viewModel.multiSelection : [element.id]
            draggingIDs = viewModel.movingGroup(for: start).union([element.id])
            viewModel.bringToFront(draggingIDs)
        } else {
            viewModel.select(element.id)   // kutu + içindekileri öne getirir
            draggingIDs = viewModel.movingGroup(for: [element.id]).union([element.id])
        }
    }

    /// Parmağın kaydırdığı yol (tuval point'i), hizaya yapışma düzeltmesi eklenmiş halde.
    /// Grup, bütün elemanlarını saran ortak kutusuyla hizalanır. Eşik ekranda sabit kalsın diye yakınlaştırmaya bölünür.
    private func snapped(_ ids: Set<UUID>, lead: CanvasElement, translation: CGSize, scale: CGFloat) -> SnapResult {
        let raw = CGSize(width: translation.width / scale, height: translation.height / scale)
        let members = viewModel.screen.elements.filter { ids.contains($0.id) }
        let union = members.map { snapBox(of: $0, layerOf: lead) }.reduce(snapBox(of: lead, layerOf: lead)) { $0.union($1) }
        let rect = union.offsetBy(dx: raw.width, dy: raw.height + edgeScrolled)
        // Sol kenar her iki katmanda aynı; çizginin boyu için kutular taşınanın katmanına çevrilir.
        let targets = viewModel.screen.elements.filter { !ids.contains($0.id) }
            .map { snapBox(of: $0, layerOf: lead) }
        var snap = SnapGuides.snapMove(rect, targets: targets, pageWidth: referenceSize.width,
                                       tolerance: SnapGuides.threshold / scale)
        snap.offset = CGSize(width: raw.width + snap.offset.width, height: raw.height + snap.offset.height)
        return snap
    }

    /// Elemanın ekranda kapladığı kutu (döndürülmüşse dönmüş hali), `mover`'ın katmanındaki point'lerle.
    /// Kayan sayfadaki eleman sabit bara göre, ya da tersi, o anki kaydırma kadar kaydırılır.
    private func snapBox(of element: CanvasElement, layerOf mover: CanvasElement) -> CGRect {
        var box = SnapGuides.boundingBox(viewModel.pointRect(of: element),
                                         degrees: element.properties.rotation ?? 0)
        if element.isPinned != mover.isPinned {
            box.origin.y += mover.isPinned ? -viewport.scroll : viewport.scroll
        }
        return box
    }

    /// Hizalama çizgileri; elemanların üstünde, dokunuş almaz. Kalınlık ekranda hep 1 point.
    /// Çizgiler taşınan elemanın katmanında hesaplanır; kayan sayfadaysa kaydırma kadar yukarı alınır.
    /// Yeni bir hizaya yapışınca telefon hafifçe titrer.
    private func guidesLayer(scale: CGFloat) -> some View {
        let mover = viewModel.screen.elements.first { draggingIDs.contains($0.id) }
        let shift = (mover?.isPinned ?? true) ? 0 : viewport.scroll
        let thickness = 1 / scale

        return ZStack(alignment: .topLeading) {
            ForEach(snapGuides, id: \.self) { guide in
                switch guide.axis {
                case .vertical:
                    let span = guide.span.map { ($0.lowerBound - shift)...($0.upperBound - shift) }
                        ?? 0...referenceSize.height
                    Rectangle()
                        .fill(Theme.snapGuide)
                        .frame(width: thickness, height: span.upperBound - span.lowerBound)
                        .offset(x: guide.position - thickness / 2, y: span.lowerBound)
                case .horizontal:
                    let span = guide.span ?? 0...referenceSize.width
                    Rectangle()
                        .fill(Theme.snapGuide)
                        .frame(width: span.upperBound - span.lowerBound, height: thickness)
                        .offset(x: span.lowerBound, y: guide.position - shift - thickness / 2)
                }
            }
        }
        .frame(width: referenceSize.width, height: referenceSize.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .sensoryFeedback(.alignment, trigger: snapGuides) { old, new in
            !new.isEmpty && new != old
        }
    }

    /// Parmak kartın görünen kısmının alt/üst kenarına yaklaştıysa sayfayı o yöne kaydırmaya başlar,
    /// uzaklaştıysa durdurur. Hız, kenara ne kadar girildiğiyle artar.
    private func updateEdgeScroll(fingerY: CGFloat) {
        let visible = cardFrame.intersection(areaFrame)
        guard !visible.isNull else { return }
        let band = Self.edgeBand
        var speed: CGFloat = 0
        if fingerY > visible.maxY - band {
            speed = min((fingerY - (visible.maxY - band)) / band, 1) * Self.maxEdgeSpeed
        } else if fingerY < visible.minY + band {
            speed = -min(((visible.minY + band) - fingerY) / band, 1) * Self.maxEdgeSpeed
        }
        edgeScrollSpeed = speed
        guard speed != 0, edgeScrollTask == nil else { return }

        edgeScrollTask = Task { @MainActor in
            while !Task.isCancelled, edgeScrollSpeed != 0 {
                let limit = CanvasViewport.maxScroll(contentHeight: contentHeight)
                let newScroll = min(max(viewport.scroll + edgeScrollSpeed, 0), limit)
                // Sayfa ne kadar kaydıysa eleman da o kadar kayar; parmağın altında kalır
                edgeScrolled += newScroll - viewport.scroll
                viewport.scroll = newScroll
                try? await Task.sleep(for: .milliseconds(16))
            }
            edgeScrollTask = nil
        }
    }

    private func stopEdgeScroll() {
        edgeScrollSpeed = 0
        edgeScrollTask?.cancel()
        edgeScrollTask = nil
    }

    /// Referans tuvalin verilen alana sığması için gereken küçültme oranı.
    private func fittedScale(in available: CGSize) -> CGFloat {
        min(available.width / referenceSize.width,
            available.height / referenceSize.height)
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    CanvasView(viewModel: EditorViewModel(catalog: catalog, screen: MockScreens.login(using: catalog)))
        .padding()
        .background(Theme.background)
}
