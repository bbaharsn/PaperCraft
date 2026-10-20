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

    // MARK: - Ortak görünüm (buton, metin kutusu, anahtar)

    /// Ana renk, hex olarak: "#AC5135". Butonda dolgu, metin kutusunda kenarlık ve ikon,
    /// anahtarda açıkken rengi.
    var fillColor: String?
    /// Yazı rengi, hex olarak. Butonda sadece dolu stilde kullanılır.
    var contentColor: String?
    /// İkonun yeri; hangi ikon olduğu `symbolName`'de durur.
    var iconPosition: IconPosition?

    // MARK: - Metin kutusu görünümü

    var border: TextFieldBorder?
    var inputKind: TextFieldKind?

    // MARK: - Anahtar görünümü

    var labelPosition: SwitchLabelPosition?
}
