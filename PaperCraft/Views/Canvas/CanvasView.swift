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
    /// Alttan bir sayfanın kapattığı yükseklik (point). Tuval küçülmez; seçili eleman
    /// bu alanın altında kalacaksa tuval o eleman görünene kadar yukarı kayar.
    var bottomInset: CGFloat = 0

    /// Şu an sürüklenen eleman ve parmağın ne kadar kaydığı (tuvalin kendi point'leri).
    /// Sürükleme bitene kadar model değişmez; sadece görüntü kayar.
    @State private var draggingID: UUID?
    @State private var dragOffset: CGSize = .zero

    /// Referans iPhone ekranı (point). Normalize koordinatlar buna göredir.
    private let referenceSize = CGSize(width: 393, height: 852)

    var body: some View {
        GeometryReader { geometry in
            let scale = fittedScale(in: geometry.size)

            elementsLayer(scale: scale)
                .frame(width: referenceSize.width, height: referenceSize.height)
                .background(Theme.paper)
                .contentShape(Rectangle())
                .onTapGesture { viewModel.select(nil) }
                // Gerçek boyutta çizilen tuvali ekrana sığacak kadar küçült
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: referenceSize.width * scale,
                       height: referenceSize.height * scale,
                       alignment: .topLeading)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .paperCard()
                .overlay(alignment: .topLeading) { tape }
                .offset(y: -liftForSelection(in: geometry.size, scale: scale))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Seçili elemanın alttaki sayfanın üstünde görünmesi için tuvalin ne kadar
    /// yukarı kayması gerektiği (ekran point'i). Eleman zaten görünüyorsa 0.
    private func liftForSelection(in available: CGSize, scale: CGFloat) -> CGFloat {
        guard bottomInset > 0, let element = viewModel.selectedElement else { return 0 }
        let margin: CGFloat = 16

        // Tuval alanın ortasına yerleşiyor; elemanın ekrandaki üst ve alt kenarı
        let cardTop = (available.height - referenceSize.height * scale) / 2
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
            ForEach(viewModel.screen.elements) { element in
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
                            SelectionOverlay(element: element, scale: scale) { corner, delta in
                                viewModel.resizeElement(element.id, from: corner, by: delta)
                            }
                        }
                    }
                    .offset(element.id == draggingID ? dragOffset : .zero)
                    .position(x: (frame.x + frame.width / 2) * referenceSize.width,
                              y: (frame.y + frame.height / 2) * referenceSize.height)
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
                if draggingID == nil {
                    draggingID = element.id
                    viewModel.select(element.id)
                }
                dragOffset = CGSize(width: value.translation.width / scale,
                                    height: value.translation.height / scale)
            }
            .onEnded { value in
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
