//
//  GroupResizeHandles.swift
//  PaperCraft
//

import SwiftUI

/// Toplu seçimin ortak çerçevesinin dört köşesindeki boyut tutamaçları. Çekilen köşe ve parmağın
/// başlangıçtan beri toplam hareketi (sayfa point'i) bildirilir; bütün grup oranı korunarak ölçeklenir.
struct GroupResizeHandles: View {
    /// Ortak çerçeve, sayfa point'iyle.
    let rect: CGRect
    /// Canvas'ın ekrana sığdırılma oranı. Tutamaçlar küçülmesin diye buna bölünür.
    let scale: CGFloat
    let onBegin: () -> Void
    let onChange: (ResizeCorner, CGSize) -> Void
    let onEnd: () -> Void

    /// Şu an çekilen köşe; çekilmiyorsa `nil`.
    @State private var activeCorner: ResizeCorner?

    private let handleSize: CGFloat = 8
    /// Parmakla kolay yakalansın diye görünen tutamaçtan büyük dokunma alanı.
    private let handleHitSize: CGFloat = 36

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(ResizeCorner.allCases, id: \.self) { corner in
                handle
                    .position(x: corner.isLeading ? rect.minX : rect.maxX,
                              y: corner.isTop ? rect.minY : rect.maxY)
                    .gesture(resizeGesture(for: corner))
            }
        }
    }

    private var handle: some View {
        Circle()
            .fill(.white)
            .overlay(Circle().stroke(.blue, lineWidth: 2 / scale))
            .frame(width: handleSize / scale, height: handleSize / scale)
            .frame(width: handleHitSize / scale, height: handleHitSize / scale)
            .contentShape(Rectangle())
    }

    private func resizeGesture(for corner: ResizeCorner) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                if activeCorner == nil {
                    activeCorner = corner
                    onBegin()
                }
                // Parmak ekran point'iyle hareket eder; canvas küçültüldüğü için `scale`'e böleriz.
                onChange(corner, CGSize(width: value.translation.width / scale,
                                        height: value.translation.height / scale))
            }
            .onEnded { _ in
                activeCorner = nil
                onEnd()
            }
    }
}

#Preview {
    GroupResizeHandles(rect: CGRect(x: 40, y: 40, width: 200, height: 80), scale: 1,
                       onBegin: {}, onChange: { _, _ in }, onEnd: {})
        .frame(width: 300, height: 200)
}
