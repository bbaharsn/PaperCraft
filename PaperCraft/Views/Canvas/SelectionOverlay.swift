//
//  SelectionOverlay.swift
//  PaperCraft
//

import SwiftUI

/// Seçili elemanın üstüne çizilen mavi çizgi ve dört boyut tutamacı.
/// Çizgi butonun kendi şeklini sarar (hap, daire...), ondan büyük olmaz.
struct SelectionOverlay: View {
    let element: CanvasElement
    /// Canvas'ın ekrana sığdırılma oranı. Çizgi ve tutamaçlar küçülmesin diye buna bölünür.
    let scale: CGFloat
    /// Bir köşe çekildikçe parmağın son hareketini (point) bildirir.
    let onResize: (ResizeCorner, CGSize) -> Void

    /// Şu an çekilen köşe; çekilmiyorsa `nil`.
    @State private var activeCorner: ResizeCorner?
    /// Sürüklemenin bir önceki adımı; her adımda sadece aradaki farkı göndeririz.
    @State private var lastTranslation: CGSize = .zero

    private let lineWidth: CGFloat = 2
    private let handleSize: CGFloat = 8
    /// Parmakla kolay yakalansın diye görünen tutamaçtan büyük dokunma alanı.
    private let handleHitSize: CGFloat = 36

    /// Seçim çizgisinin saracağı şekil. Şekli olmayan elemanlar düz dikdörtgen çerçeve alır (`nil`).
    /// Metin kutusu da kenarlığına göre buton şekillerinden birine eşlenir.
    private var buttonShape: ButtonShape? {
        switch element.type {
        case .button:
            return element.properties.shape ?? .rounded
        case .textField:
            switch element.properties.border ?? .roundedBorder {
            case .roundedBorder: return .rounded
            case .capsule: return .capsule
            case .underline, .none: return .rectangle
            }
        default:
            return nil
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            let outline = buttonShape?.outline ?? AnyShape(Rectangle())

            ZStack {
                outline
                    .stroke(.blue, lineWidth: lineWidth / scale)
                    // Çizginin yarısı dışarı taşmasın; şeklin tam içinde kalsın.
                    .padding(lineWidth / scale / 2)
                    .allowsHitTesting(false)
                // Mavinin hemen içindeki ince beyaz çizgi: mavi bir butonda da seçim görünsün.
                outline
                    .stroke(.white, lineWidth: 1 / scale)
                    .padding(lineWidth / scale + 0.5 / scale)
                    .allowsHitTesting(false)

                ForEach(ResizeCorner.allCases, id: \.self) { corner in
                    handle
                        .position(handlePoint(for: corner, in: size))
                        .gesture(resizeGesture(for: corner))
                }

                if activeCorner != nil {
                    sizeLabel(for: size)
                        .position(x: size.width / 2, y: size.height + 16 / scale)
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private var handle: some View {
        Circle()
            .fill(.white)
            .overlay(Circle().stroke(.blue, lineWidth: lineWidth / scale))
            .frame(width: handleSize / scale, height: handleSize / scale)
            .frame(width: handleHitSize / scale, height: handleHitSize / scale)
            .contentShape(Rectangle())
    }

    /// Çekerken altta beliren "200 × 50" etiketi.
    private func sizeLabel(for size: CGSize) -> some View {
        Text("\(Int(size.width.rounded())) × \(Int(size.height.rounded()))")
            .font(.system(size: 11 / scale, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6 / scale)
            .padding(.vertical, 2 / scale)
            .background(.blue, in: RoundedRectangle(cornerRadius: 5 / scale))
            .fixedSize()
            .allowsHitTesting(false)
    }

    /// Tutamacın yeri: şeklin köşesine en yakın, çizginin tam üstündeki nokta.
    /// Köşe kıvrımlıysa 45°'deki noktaya oturur (yarıçap × (1 − 1/√2) kadar içeride).
    private func handlePoint(for corner: ResizeCorner, in size: CGSize) -> CGPoint {
        var bounds = CGRect(origin: .zero, size: size)
        if buttonShape == .circle {
            // Daire, çerçevenin ortasındaki karede çizilir.
            let side = min(size.width, size.height)
            bounds = CGRect(x: (size.width - side) / 2, y: (size.height - side) / 2, width: side, height: side)
        }

        let radius = buttonShape?.cornerRadius(in: bounds.size) ?? 0
        let inset = radius * (1 - 1 / 2.0.squareRoot())

        return CGPoint(x: corner.isLeading ? bounds.minX + inset : bounds.maxX - inset,
                       y: corner.isTop ? bounds.minY + inset : bounds.maxY - inset)
    }

    private func resizeGesture(for corner: ResizeCorner) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                activeCorner = corner
                // Parmak ekran point'iyle hareket eder; canvas küçültüldüğü için `scale`'e böleriz.
                let delta = CGSize(width: (value.translation.width - lastTranslation.width) / scale,
                                   height: (value.translation.height - lastTranslation.height) / scale)
                lastTranslation = value.translation
                onResize(corner, delta)
            }
            .onEnded { _ in
                activeCorner = nil
                lastTranslation = .zero
            }
    }
}
