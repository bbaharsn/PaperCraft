//
//  NormalizedFrame.swift
//  PaperCraft
//

import Foundation

/// Referans ekrana (393×852 pt) göre normalize edilmiş konum ve boyut. `x` ve `y` elemanın sol üst köşesidir.
/// `x` ve `width` ekran genişliğine göre 0...1'dir. `y` ve `height` ekran yüksekliği birimindedir;
/// sayfa kayabildiği için `y` 1'i geçebilir (`y = 1.5` ikinci ekranın ortası).
nonisolated struct NormalizedFrame: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}
