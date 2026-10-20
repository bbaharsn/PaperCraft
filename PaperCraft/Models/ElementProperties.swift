//
//  ElementProperties.swift
//  PaperCraft
//

import Foundation

/// Bir elemanın düzenlenebilir özellikleri.
/// Her alan opsiyoneldir; her tür yalnızca kendisini ilgilendiren alanları kullanır.
/// Alan adları `ComponentCatalog.json` içindeki `defaultProperties` ile aynıdır.
nonisolated struct ElementProperties: Codable, Equatable {
    var text: String?
    var placeholder: String?
    var style: String?
    var textStyle: String?
    var symbolName: String?
    var contentMode: String?
    var isOn: Bool?
    var value: Double?
    var minValue: Double?
    var maxValue: Double?
    var titleDisplayMode: String?
    var showsBackButton: Bool?
    var selectedIndex: Int?
    var items: [TabItem]?

    // MARK: - Buton görünümü

    var shape: ButtonShape?
    var fill: ButtonFill?
    /// Ana renk, hex olarak: "#AC5135"
    var fillColor: String?
    /// Dolu butondaki yazı ve ikon rengi, hex olarak
    var contentColor: String?
    /// İkonun yeri; hangi ikon olduğu `symbolName`'de durur.
    var iconPosition: IconPosition?
}
