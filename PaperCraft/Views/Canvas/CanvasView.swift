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
    /// Bir elemana çift dokunulunca (seçildikten sonra) çağrılır; ör. Özellikler sayfasını açmak için.
    var onDoubleTap: () -> Void = {}
    /// Sayfada boş bir yere çift dokunulunca çağrılır; ör. arka plan ayarlarını açmak için.
    var onBackgroundDoubleTap: () -> Void = {}
    /// Alttan bir sayfanın kapattığı yükseklik (point). Tuval küçülmez; seçili eleman
    /// bu alanın altında kalacaksa tuval o eleman görünene kadar yukarı kayar.
    var bottomInset: CGFloat = 0
    /// Kartın ekrandaki yeri değişince çağrılır; önizleme buradan büyür.
    var onCardFrameChange: (CGRect) -> Void = { _ in }

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

    /// Referans iPhone ekranı (point). Normalize koordinatlar buna göredir; önizleme de aynısını kullanır.
    static let referenceSize = CGSize(width: 393, height: 852)
    private let referenceSize = Self.referenceSize

    var body: some View {
        GeometryReader { geometry in
            let available = geometry.size
            let fitted = fittedScale(in: available)
            // Kartın alana tam sığdığı boyut; yakınlaştırma bunun katıdır.
            let fittedCard = CGSize(width: referenceSize.width * fitted, height: referenceSize.height * fitted)
            let scale = fitted * viewport.zoom

            card(scale: scale, available: available)
                // Büyüyen kart alanın ortasında kalır, taşan kısmı kenarlardan dışarı çıkar.
                .frame(width: available.width, height: available.height)
                // Büyütülmüş kart üst barın ve saatin arkasına taşmasın (editörün 16 pt kenar boşluğu dahil).
                // Yakınlaştırma yokken kırpılmaz: seçili eleman için yukarı kayan kart üst barın altından geçer.
                .clipShape(Rectangle().inset(by: viewport.isZoomed ? -16 : -10_000))
                .contentShape(Rectangle())
                // Elemanların kendi taşıma hareketi önce gelir; boş yerde sürüklemek kartı kaydırır.
                .gesture(panGesture(cardSize: fittedCard, available: available),
                         including: viewport.isZoomed ? .all : .subviews)
                .simultaneousGesture(pinchGesture(cardSize: fittedCard, available: available))
                .overlay(alignment: .topTrailing) {
                    if viewport.isZoomed { zoomBadge }
                }
        }
    }

    /// Kağıt kart: elemanlar, arka plan, bant. Yakınlaştırma ve kaydırma uygulanmış halde.
    private func card(scale: CGFloat, available: CGSize) -> some View {
            elementsLayer(scale: scale)
                .frame(width: referenceSize.width, height: referenceSize.height)
                // Dokunuşlar arka planın üstünde; elemana dokunmak buraya gelmez.
                .background(
                    ScreenBackgroundView(background: viewModel.screen.background)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { onBackgroundDoubleTap() }
                        // Tek dokunuş beklemeden hemen seçimi kaldırsın diye çift dokunuşla aynı anda dinlenir.
                        .simultaneousGesture(TapGesture().onEnded { viewModel.select(nil) })
                )
                // Gerçek boyutta çizilen tuvali ekrana sığacak kadar küçült
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: referenceSize.width * scale,
                       height: referenceSize.height * scale,
                       alignment: .topLeading)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .paperCard()
                .overlay(alignment: .topLeading) { tape }
                .offset(x: viewport.pan.width,
                        y: viewport.pan.height - liftForSelection(in: available, scale: scale))
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { onCardFrameChange($0) }
    }

    /// Yakınlaştırılmışken sağ üstte görünen oran; dokununca kart yeniden alana sığar.
    private var zoomBadge: some View {
        Button {
            withAnimation(.snappy) { viewport = CanvasViewport() }
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
                    withAnimation(.snappy) { viewport = CanvasViewport() }
                }
            }
    }

    /// Yakınlaştırılmışken boş bir yerde sürükleyince kart kayar.
    private func panGesture(cardSize: CGSize, available: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard !isPinching else { return }
                if gestureStart == nil { gestureStart = viewport }
                guard let start = gestureStart else { return }
                viewport = .dragged(from: start, by: value.translation, cardSize: cardSize, available: available)
            }
            .onEnded { _ in
                if !isPinching { gestureStart = nil }
            }
    }

    /// Seçili elemanın alttaki sayfanın üstünde görünmesi için tuvalin ne kadar
    /// yukarı kayması gerektiği (ekran point'i). Eleman zaten görünüyorsa 0.
    private func liftForSelection(in available: CGSize, scale: CGFloat) -> CGFloat {
        guard bottomInset > 0, let element = viewModel.selectedElement else { return 0 }
        let margin: CGFloat = 16

        // Tuval alanın ortasına (kaydırıldıysa o kadar ötesine) yerleşiyor; elemanın ekrandaki üst ve alt kenarı
        let cardTop = (available.height - referenceSize.height * scale) / 2 + viewport.pan.height
        let elementTop = cardTop + element.frame.y * referenceSize.height * scale
        let elementBottom = elementTop + element.frame.height * referenceSize.height * scale

        let visibleBottom = available.height - bottomInset - margin
        let needed = elementBottom - visibleBottom
        // Eleman çok uzunsa üst kenarı ekrandan çıkacak kadar kaydırma
        return max(0, min(needed, elementTop - margin))
    }

    /// Tüm elemanlar, gerçek iPhone point'leriyle yerleştirilmiş halde.
    private func elementsLayer(scale: CGFloat) -> some View {
        ZStack {
            ForEach(Array(viewModel.screen.elements.enumerated()), id: \.element.id) { index, element in
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
                    .offset(element.id == draggingID ? dragOffset : .zero)
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
            }
            .onEnded { value in
                // Yakınlaştırma yüzünden iptal edildiyse eleman yerinde kalır
                guard draggingID == element.id else { return }
                // Ekran point'i → normalize (0...1) dönüşümü
                viewModel.moveElement(element.id,
                                      dx: value.translation.width / (referenceSize.width * scale),
                                      dy: value.translation.height / (referenceSize.height * scale))
                draggingID = nil
                dragOffset = .zero
            }
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
