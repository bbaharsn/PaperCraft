//
//  DeviceKind.swift
//  PaperCraft
//

import CoreGraphics

/// Projenin hangi cihaz için tasarlandığı. Tuvalin boyutu buna göredir;
/// elemanların normalize konumları (`NormalizedFrame`) bu boyuta oranlanır.
nonisolated enum DeviceKind: String, Codable, CaseIterable {
    case iPhone
    /// Yatay tutulan iPhone; dikey iPhone'un döndürülmüş tuvali.
    case iPhoneLandscape
    case iPad
    /// Yatay tutulan iPad; dikey iPad'in döndürülmüş tuvali.
    case iPadLandscape

    /// Tuvalin gerçek boyutu (point).
    var canvasSize: CGSize {
        switch self {
        case .iPhone: CGSize(width: 393, height: 852)   // iPhone 15/16
        case .iPhoneLandscape: CGSize(width: 852, height: 393)
        case .iPad: CGSize(width: 820, height: 1180)    // iPad Air 11", dikey
        case .iPadLandscape: CGSize(width: 1180, height: 820)
        }
    }

    /// Menüde ve proje kartında görünen ad.
    var title: String {
        switch self {
        case .iPhone: "iPhone"
        case .iPhoneLandscape: "iPhone (yatay)"
        case .iPad: "iPad"
        case .iPadLandscape: "iPad (yatay)"
        }
    }

    /// SF Symbol adı.
    var symbolName: String {
        switch self {
        case .iPhone: "iphone"
        case .iPhoneLandscape: "iphone.landscape"
        case .iPad: "ipad"
        case .iPadLandscape: "ipad.landscape"
        }
    }

    /// iPad tuvali mi (dikey ya da yatay)?
    var isPad: Bool { self == .iPad || self == .iPadLandscape }

    /// Tuval yatay mı?
    var isLandscape: Bool { canvasSize.width > canvasSize.height }

    /// "Yeni proje" menüsünün sırası: kullanıcının elindeki cihazın dikey ve yatay seçenekleri en üstte.
    static func menuOrder(preferred: DeviceKind) -> [DeviceKind] {
        allCases.filter { $0.isPad == preferred.isPad } + allCases.filter { $0.isPad != preferred.isPad }
    }
}
