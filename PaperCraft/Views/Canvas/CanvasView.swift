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

    /// Şu an sürüklenen eleman ve parmağın ne kadar kaydığı (tuvalin kendi point'leri).
    /// Sürükleme bitene kadar model değişmez; sadece görüntü kayar.
    @State private var draggingID: UUID?
    @State private var dragOffset: CGSize = .zero

    /// İki parmakla yakınlaştırma ve kaydırma durumu.
    @State private var viewport = CanvasViewport()
    /// Yakınlaştırma ya da kaydırma başladığındaki durum; hareket buna göre hesaplanır.
    @State private var gestureStart: CanvasViewport?
    /// İki parmak ekrandayken eleman taşınmasın.
    @State private var isPinching = false

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
                .simultaneousGesture(pinchGesture(cardSize: fittedCard, available: available))
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
                if contentHeight > 1 {
                    PageEndLine(scale: scale)
                        .frame(width: referenceSize.width)
                        .offset(y: CGFloat(contentHeight) * referenceSize.height)
                }
            }
            .frame(width: referenceSize.width, height: scrollableHeight, alignment: .topLeading)
            .offset(y: -viewport.scroll)

            // Sabit üst bar ve alt menü kaymaz; içerik altından geçer.
            elementsLayer(scale: scale, pinned: true)
                .frame(width: referenceSize.width, height: referenceSize.height)
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
        .onTapGesture(count: 2) { onBackgroundDoubleTap() }
        // Tek dokunuş beklemeden hemen seçimi kaldırsın diye çift dokunuşla aynı anda dinlenir.
        .simultaneousGesture(TapGesture().onEnded {
            viewModel.select(nil)
            onBackgroundTap()
        })
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
    private func pinchGesture(cardSize: CGSize, available: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if gestureStart == nil {
                    gestureStart = viewport
                    isPinching = true
                    // İlk parmakla başlamış bir eleman taşıması iptal olur, eleman yerine döner.
                    draggingID = nil
                    dragOffset = .zero
                }
                guard let start = gestureStart else { return }
                let anchor = CGPoint(x: value.startLocation.x - available.width / 2,
                                     y: value.startLocation.y - available.height / 2)
                viewport = .pinched(from: start, magnification: value.magnification, anchor: anchor,
                                    cardSize: cardSize, available: available)
            }
            .onEnded { _ in
                gestureStart = nil
                isPinching = false
                if !viewport.isZoomed {
                    withAnimation(.snappy) { viewport = CanvasViewport(scroll: viewport.scroll) }
                }
            }
    }

    /// Boş bir yerde sürükleyince sayfa kayar; büyütülmüşse önce kart kendi sınırına kadar kayar.
    private func panGesture(cardSize: CGSize, available: CGSize, scale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard !isPinching else { return }
                if gestureStart == nil { gestureStart = viewport }
                guard let start = gestureStart else { return }
                viewport = .dragged(from: start, by: value.translation, cardSize: cardSize, available: available,
                                    scale: scale, contentHeight: contentHeight)
            }
            .onEnded { _ in
                if !isPinching { gestureStart = nil }
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
                let isSelected = element.id == viewModel.selectedElementID

                ElementView(element: element)
                    .allowsHitTesting(false)
                    .frame(width: frame.width * referenceSize.width,
                           height: frame.height * referenceSize.height)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        viewModel.select(element.id)
                        onDoubleTap()
                    }
                    // Tek dokunuş beklemeden hemen seçsin diye çift dokunuşla aynı anda dinlenir.
                    .simultaneousGesture(TapGesture().onEnded { viewModel.select(element.id) })
                    // Basılı tutmak da çift dokunuş gibi Özellikler'i açar. Parmak kayarsa iptal olur, taşıma başlar.
                    .simultaneousGesture(LongPressGesture(minimumDuration: Self.longPressDuration).onEnded { _ in
                        guard draggingID == nil, !isPinching else { return }
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
                        }
                    }
                    // Seçim çizgisi de elemanla birlikte döner
                    .rotationEffect(.degrees(element.properties.rotation ?? 0))
                    .offset(element.id == draggingID
                            ? CGSize(width: dragOffset.width, height: dragOffset.height + edgeScrolled)
                            : .zero)
                    .position(x: (frame.x + frame.width / 2) * referenceSize.width,
                              y: (frame.y + frame.height / 2) * referenceSize.height)
                    // ZStack sıra değişince çizim sırasını her zaman güncellemiyor; dizideki sırayı açıkça veriyoruz.
                    .zIndex(Double(index))
            }
        }
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
                guard !isPinching else { return }
                if draggingID == nil {
                    draggingID = element.id
                    viewModel.select(element.id)
                }
                dragOffset = CGSize(width: value.translation.width / scale,
                                    height: value.translation.height / scale)
                if !element.isPinned {
                    updateEdgeScroll(fingerY: value.location.y)
                }
            }
            .onEnded { value in
                stopEdgeScroll()
                // Yakınlaştırma yüzünden iptal edildiyse eleman yerinde kalır
                guard draggingID == element.id else { return }
                // Ekran point'i → normalize dönüşümü; kenarda kendiliğinden kayılan yol da eklenir
                viewModel.moveElement(element.id,
                                      dx: value.translation.width / (referenceSize.width * scale),
                                      dy: (value.translation.height / scale + edgeScrolled) / referenceSize.height)
                draggingID = nil
                dragOffset = .zero
                edgeScrolled = 0
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
