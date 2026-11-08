//
//  ImageContentMode.swift
//  PaperCraft
//

import Foundation

/// Fotoğrafın elemanın çerçevesine nasıl yerleşeceği.
nonisolated enum ImageContentMode: String, Codable, CaseIterable {
    /// Fotoğrafın tamamı görünür; oranı çerçeveden farklıysa kenarlarda boşluk kalır.
    case fit
    /// Fotoğraf çerçeveyi doldurur, taşan kısmı kırpılır. Yuvarlak profil fotoğrafı bununla olur.
    case fill

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .fit: "Sığdır"
        case .fill: "Doldur"
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.fit` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = ImageContentMode(rawValue: rawValue) ?? .fit
    }
}
