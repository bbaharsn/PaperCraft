//
//  Theme.swift
//  PaperCraft
//

import SwiftUI

/// Uygulamanın renkleri ve yazı tipleri. Tasarım değişirse sadece burası değişir.
enum Theme {

    // MARK: - Renkler

    /// Ekranın kum rengi arka planı
    static let background = Color(hex: 0xDDCEB3)
    /// Kağıt kartın (canvas) rengi
    static let paper = Color(hex: 0xFBF7EE)
    /// Yazılar, kenarlıklar ve gölge (koyu kahve)
    static let ink = Color(hex: 0x2B2118)
    /// Vurgu rengi ("Başla" butonu, logodaki nokta)
    static let accent = Color(hex: 0xAC5135)
    /// Canvas üzerindeki bant
    static let tape = Color(hex: 0xEBD9A9)
    /// Alt katalog paneli ve seçili sekme
    static let panel = Color(hex: 0xF7F1E5)
    /// Seçili olmayan sekmeler
    static let tabInactive = Color(hex: 0xE8DEC7)

    // MARK: - Ölçüler

    static let cornerRadius: CGFloat = 12
    /// Bulanık olmayan "kağıt" gölgesinin kayması
    static let shadowOffset = CGSize(width: 2, height: 3)

    // MARK: - Yazı tipleri

    /// Logo fontunun dosya içindeki gerçek adı (dosya adı değil!).
    static let logoFontName = "BricolageGrotesque24ptSemiCondensed-ExtraBold"

    /// "papercraft." logosu. Font bulunamazsa sistem fontuna düşer.
    static func logoFont(size: CGFloat) -> Font {
        .custom(logoFontName, size: size)
    }
}

#Preview("Renkler") {
    let swatches: [(String, Color)] = [
        ("background", Theme.background), ("paper", Theme.paper), ("ink", Theme.ink),
        ("accent", Theme.accent), ("tape", Theme.tape), ("panel", Theme.panel),
        ("tabInactive", Theme.tabInactive),
    ]
    VStack(alignment: .leading) {
        ForEach(swatches, id: \.0) { name, color in
            HStack {
                RoundedRectangle(cornerRadius: 6).fill(color)
                    .frame(width: 60, height: 36)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.gray))
                Text(name)
            }
        }
    }
    .padding()
}
