//
//  ElementResizeStart.swift
//  PaperCraft
//

import CoreGraphics
import Foundation

/// Bir elemanın köşesi çekilmeye başladığındaki hali. İçerik ölçeği her adımda buna göre hesaplanır;
/// adım adım çarpmak, parmak bir yana bir öbür yana kaydıkça hatayı biriktirirdi.
nonisolated struct ElementResizeStart {
    let id: UUID
    let rect: CGRect
    let contentScale: Double?
    /// Parmağın başlangıçtan beri elemanın kendi eksenlerindeki toplam hareketi (point).
    var translation: CGSize = .zero
    /// Son adımda elemana verilen çerçeve. Eleman başka bir yoldan değiştiyse (taşındı, geri alındı)
    /// bu kayıt eskimiştir ve yeni çekiş baştan başlar.
    var lastRect: CGRect
}
