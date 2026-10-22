//
//  TabItem.swift
//  PaperCraft
//

import Foundation

/// TabBar içindeki tek bir sekme.
nonisolated struct TabItem: Codable, Equatable {
    var text: String
    var symbolName: String

    /// Bir alt menüde olabilecek sekme sayısı. Apple en çok 5 öneriyor; tek sekmeli menü anlamsız.
    static let allowedCount = 2...5
}
