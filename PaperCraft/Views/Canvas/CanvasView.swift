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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.blue, lineWidth: 2)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.select(element.id) }
                    .gesture(dragGesture(for: element, scale: scale))
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
