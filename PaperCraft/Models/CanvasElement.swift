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
}
