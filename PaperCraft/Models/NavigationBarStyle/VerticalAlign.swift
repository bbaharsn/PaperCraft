//
//  VerticalAlign.swift
//  PaperCraft
//

import Foundation

/// Bir içeriğin eleman çerçevesi içindeki dikey yeri (ör. üst bar uzatılınca başlık nerede dursun).
nonisolated enum VerticalAlign: String, Codable, CaseIterable {
    case top
    case center
    case bottom

    /// Özellikler sayfasında görünen ad.
    var title: String {
        switch self {
        case .top: "Üstte"
        case .center: "Ortada"
        case .bottom: "Altta"
        }
    }

    /// Tanımadığımız bir değer gelirse (ör. AI uydurduysa) çökmek yerine `.center` olur.
    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = VerticalAlign(rawValue: rawValue) ?? .center
    }
}
