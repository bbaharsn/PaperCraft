//
//  PrototypeScreen.swift
//  PaperCraft
//

import Foundation

/// Bir prototipteki tek bir ekran.
/// `elements` dizisindeki sıra çizim sırasıdır: sondaki eleman en üstte görünür.
nonisolated struct PrototypeScreen: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var elements: [CanvasElement] = []
}
