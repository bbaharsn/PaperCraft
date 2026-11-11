//
//  GroupMove.swift
//  PaperCraft
//

import Foundation

/// Birlikte taşınan elemanların kaymasını tek parça sınırlar. Kenara dayanan eleman durup
/// diğerleri devam etseydi aradaki boşluklar bozulurdu; bunun yerine bütün grup aynı yerde durur.
nonisolated enum GroupMove {
    /// Normalize birimlerle. Grubun ortak sınırı yanlardan ve üstten taşmaz; aşağıda sayfa uzar.
    /// `keepsOnScreen` true ise (sabit üst bar / alt menü) alttan da ekranın içinde kalır.
    static func clamped(dx: Double, dy: Double, frames: [NormalizedFrame],
                        keepsOnScreen: Bool) -> (dx: Double, dy: Double) {
        guard !frames.isEmpty else { return (dx, dy) }
        let minX = frames.map(\.x).min()!
        let maxX = frames.map { $0.x + $0.width }.max()!
        let minY = frames.map(\.y).min()!
        let maxY = frames.map { $0.y + $0.height }.max()!

        // Grup ekrandan genişse sol kenar esas alınır.
        let clampedX = max(min(dx, 1 - maxX), -minX)
        var clampedY = max(dy, -minY)
        if keepsOnScreen {
            clampedY = max(min(clampedY, 1 - maxY), -minY)
        }
        return (clampedX, clampedY)
    }
}
