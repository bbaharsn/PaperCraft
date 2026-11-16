//
//  DeviceKind.swift
//  PaperCraft
//

import CoreGraphics

/// Projenin hangi cihaz için tasarlandığı. Tuvalin boyutu buna göredir;
/// elemanların normalize konumları (`NormalizedFrame`) bu boyuta oranlanır.
nonisolated enum DeviceKind: String, Codable, CaseIterable {
    case iPhone
    case iPad

    /// Tuvalin gerçek boyutu (point).
    var canvasSize: CGSize {
        switch self {
        case .iPhone: CGSize(width: 393, height: 852)   // iPhone 15/16
        case .iPad: CGSize(width: 820, height: 1180)    // iPad Air 11", dikey
        }
    }

    /// Menüde ve proje kartında görünen ad.
    var title: String {
        switch self {
        case .iPhone: "iPhone"
        case .iPad: "iPad"
        }
    }

    /// SF Symbol adı.
    var symbolName: String {
        switch self {
        case .iPhone: "iphone"
        case .iPad: "ipad"
        }
    }

    /// "Yeni proje" menüsünün sırası: kullanıcının elindeki cihaz en üstte.
    static func menuOrder(preferred: DeviceKind) -> [DeviceKind] {
        [preferred] + allCases.filter { $0 != preferred }
    }
}
