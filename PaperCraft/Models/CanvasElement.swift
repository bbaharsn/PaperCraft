//
//  CanvasElement.swift
//  PaperCraft
//

import Foundation

/// Canvas üzerindeki tek bir eleman.
nonisolated struct CanvasElement: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var type: ElementType
    var frame: NormalizedFrame
    var properties: ElementProperties

    /// Sayfa kayarken ekranda yerinde duran eleman mı? Sadece "Sabit" üst bar ve alt menü.
    /// Böyle bir elemanın `frame.y`'si sayfaya değil ekranın görünen kısmına göredir (0...1).
    var isPinned: Bool {
        (type == .navigationBar || type == .tabBar) && (properties.scrollBehavior ?? .fixed) == .fixed
    }
}
