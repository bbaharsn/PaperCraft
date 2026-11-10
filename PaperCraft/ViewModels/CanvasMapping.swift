//
//  CanvasMapping.swift
//  PaperCraft
//

import CoreGraphics

/// Ekrandaki bir noktanın (global point) sayfanın neresine denk geldiğini hesaplar.
/// Katalogdan sürüklenen eleman bırakılınca kullanılır.
struct CanvasMapping: Equatable {
    /// Kartın ekrandaki yeri (yakınlaştırma ve kaydırma dahil).
    var cardFrame: CGRect
    /// Kartın görünen kısmı; büyütülmüş kartın taşan yeri burada değildir.
    var visibleFrame: CGRect
    /// Ekran point'inin tuval point'ine oranı (küçültme × yakınlaştırma).
    var scale: CGFloat
    /// Sayfanın ne kadar aşağı kaydırıldığı (tuval point'i).
    var scroll: CGFloat

    /// Referans iPhone ekranı (point); normalize koordinatlar buna göredir.
    static let referenceSize = CGSize(width: 393, height: 852)

    /// Canvas alanı (`area`, global) ve görünüm durumundan kartın yerini çıkarır.
    /// Kart alanın ortasındadır; büyütülüp kaydırıldıysa `pan` kadar ötesinde.
    init(area: CGRect, viewport: CanvasViewport) {
        let reference = Self.referenceSize
        let fitted = min(area.width / reference.width, area.height / reference.height)
        scale = fitted * viewport.zoom
        let size = CGSize(width: reference.width * scale, height: reference.height * scale)
        cardFrame = CGRect(x: area.midX - size.width / 2 + viewport.pan.width,
                           y: area.midY - size.height / 2 + viewport.pan.height,
                           width: size.width, height: size.height)
        visibleFrame = cardFrame.intersection(area)
        scroll = viewport.scroll
    }

    /// Ekrandaki nokta sayfanın neresinde (normalize; y sayfa kaydırması dahil)?
    /// Nokta kartın görünen kısmının dışındaysa `nil`.
    func pagePoint(forGlobal point: CGPoint) -> CGPoint? {
        guard !visibleFrame.isNull, visibleFrame.contains(point), scale > 0 else { return nil }
        let reference = Self.referenceSize
        let x = (point.x - cardFrame.minX) / scale
        let y = (point.y - cardFrame.minY) / scale + scroll
        return CGPoint(x: x / reference.width, y: y / reference.height)
    }
}
