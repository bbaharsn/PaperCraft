//
//  ComponentPlacement.swift
//  PaperCraft
//

import Foundation

/// Yeni eklenen bir elemanın ekranda nereye yerleşeceği.
nonisolated enum ComponentPlacement: String, Decodable {
    /// Ekranın ortasına yerleşir, serbestçe taşınabilir.
    case free
    /// Ekranın en üstüne yapışır (ör. NavigationBar).
    case top
    /// Ekranın en altına yapışır (ör. TabBar).
    case bottom
}
