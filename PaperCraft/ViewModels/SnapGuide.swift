//
//  SnapGuide.swift
//  PaperCraft
//

import CoreGraphics

/// Sürüklerken hizaya gelince çizilen ince çizgi. Konumlar, taşınan elemanın katmanındaki
/// referans ekran point'iyle (kayan elemanda sayfaya, sabit barda ekrana göre).
nonisolated struct SnapGuide: Equatable, Hashable {
    enum Axis: Hashable, Comparable {
        /// Dikey çizgi: x'te hiza (sol, orta, sağ).
        case vertical
        /// Yatay çizgi: y'de hiza (üst, orta, alt).
        case horizontal
    }

    var axis: Axis
    /// Dikey çizgide x, yatay çizgide y.
    var position: CGFloat
    /// Çizginin uzandığı aralık (dikeyde y, yatayda x). `nil` ise kart boyunca (sayfa ortası).
    var span: ClosedRange<CGFloat>? = nil
}
