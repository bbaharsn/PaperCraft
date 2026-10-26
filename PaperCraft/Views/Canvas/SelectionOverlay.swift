//
//  SelectionOverlay.swift
//  PaperCraft
//

import SwiftUI

/// Seçili elemanın üstüne çizilen mavi çizgi, dört boyut tutamacı ve (verilmişse) döndürme tutamacı.
/// Çizgi butonun kendi şeklini sarar (hap, daire...), ondan büyük olmaz.
struct SelectionOverlay: View {
    let element: CanvasElement
    /// Canvas'ın ekrana sığdırılma oranı. Çizgi ve tutamaçlar küçülmesin diye buna bölünür.
    let scale: CGFloat
    /// Bir köşe çekildikçe parmağın son hareketini (point) bildirir.
    let onResize: (ResizeCorner, CGSize) -> Void
    /// Döndürme tutamacı çekildikçe yeni açıyı (derece) bildirir; `nil` ise tutamaç çizilmez.
    var onRotate: ((Double) -> Void)? = nil

    /// Şu an çekilen köşe; çekilmiyorsa `nil`.
    @State private var activeCorner: ResizeCorner?
    /// Sürüklemenin bir önceki adımı; her adımda sadece aradaki farkı göndeririz.
    @State private var lastTranslation: CGSize = .zero
    /// Döndürme başladığındaki açı ve tutamacın merkeze göre yeri (ekran point'i); döndürülmüyorsa `nil`.
    @State private var rotationStart: (angle: Double, handle: CGSize)?

    private let lineWidth: CGFloat = 2
    private let handleSize: CGFloat = 8
    /// Parmakla kolay yakalansın diye görünen tutamaçtan büyük dokunma alanı.
    private let handleHitSize: CGFloat = 36
    /// Döndürme tutamacının sağ üst köşeden çapraz uzaklığı (ekran point'i).
    private let rotateHandleOffset: CGFloat = 30

    private var rotation: Double { element.properties.rotation ?? 0 }

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
        case .tabBar:
            return (element.properties.tabBarCorner ?? .square).buttonShape
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

                // Köşe tutamaçlarından sonra eklenir; dokunma alanları çakışırsa döndürme kazanır.
                if let onRotate {
                    rotateHandle
                        .position(x: size.width + rotateHandleOffset / scale, y: -rotateHandleOffset / scale)
                        .gesture(rotateGesture(in: size, onRotate: onRotate))
                }

                if activeCorner != nil {
                    label("\(Int(size.width.rounded())) × \(Int(size.height.rounded()))")
                        .position(x: size.width / 2, y: size.height + 16 / scale)
                } else if rotationStart != nil {
                    label("\(Int(rotation.rounded()))°")
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

    /// Sağ üst köşenin çaprazındaki yuvarlak döndürme tutamacı.
    private var rotateHandle: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: 10 / scale, weight: .bold))
            .foregroundStyle(.blue)
            .frame(width: 20 / scale, height: 20 / scale)
            .background(Circle().fill(.white))
            .overlay(Circle().stroke(.blue, lineWidth: lineWidth / scale))
            .frame(width: handleHitSize / scale, height: handleHitSize / scale)
            .contentShape(Rectangle())
    }

    /// Çekerken altta beliren etiket: "200 × 50" ya da "45°".
    private func label(_ text: String) -> some View {
        Text(text)
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

    /// Tutamaç elemanın ortası etrafında döner: parmağın ortaya göre açısı ne kadar değiştiyse
    /// eleman da o kadar döner. Hesap ekran point'iyle yapılır (parmak orada hareket eder).
    private func rotateGesture(in size: CGSize, onRotate: @escaping (Double) -> Void) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                let start = rotationStart ?? (rotation, handleVector(in: size))
                rotationStart = start

                let finger = CGSize(width: start.handle.width + value.translation.width,
                                    height: start.handle.height + value.translation.height)
                let turned = Double(atan2(finger.height, finger.width) - atan2(start.handle.height, start.handle.width))
                onRotate(start.angle + turned * 180 / Double.pi)
            }
            .onEnded { _ in
                rotationStart = nil
            }
    }

    /// Döndürme tutamacının elemanın ortasına göre yeri, ekran point'iyle ve elemanın şu anki açısıyla.
    private func handleVector(in size: CGSize) -> CGSize {
        let x: CGFloat = (size.width / 2) * scale + rotateHandleOffset
        let y: CGFloat = -(size.height / 2) * scale - rotateHandleOffset
        let angle = CGFloat(rotation) * .pi / 180
        return CGSize(width: x * cos(angle) - y * sin(angle),
                      height: x * sin(angle) + y * cos(angle))
    }
}
