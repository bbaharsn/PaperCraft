//
//  NormalizedFrame.swift
//  PaperCraft
//

import Foundation

/// Referans ekrana (393×852 pt) göre 0...1 aralığında normalize edilmiş konum ve boyut.
/// `x` ve `y` elemanın sol üst köşesidir.
nonisolated struct NormalizedFrame: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}
