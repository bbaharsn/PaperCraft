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
    var textStyle: TextFontStyle?
    var symbolName: String?
    var contentMode: String?
    var isOn: Bool?
    var value: Double?
    var minValue: Double?
    var maxValue: Double?
    var titleDisplayMode: NavigationTitleMode?
    var showsBackButton: Bool?
    var selectedIndex: Int?
    var items: [TabItem]?

    // MARK: - Buton görünümü

    var shape: ButtonShape?
    var fill: ButtonFill?

    // MARK: - Metin görünümü

    /// Yazı tipi ailesinin adı (metin ve üst bar başlığı): "Avenir Next", "Georgia" ... `FontFamilies.system` ya da boşsa sistem yazı tipi.
    /// Cihazda olmayan bir ad gelirse iOS sessizce sistem yazı tipine düşer.
    var fontName: String?
    var fontWeight: TextWeight?
    /// Yazı eğik (italik) mi
    var isItalic: Bool?
    /// Metnin ya da üst bar başlığının yatay yeri
    var textAlignment: TextAlign?

    // MARK: - Üst bar görünümü

    /// Geri okunun yanındaki yazı ("Geri"); boşsa sadece ok görünür.
    var backTitle: String?
    /// Sağdaki buton; ikon olursa hangi ikon olduğu `symbolName`'de durur.
    var trailingItem: NavigationTrailingItem?
    /// Sağdaki butonun yazısı ("Düzenle")
    var trailingText: String?
    /// Geri ve sağ butonun rengi, hex olarak.
    var tintColor: String?
    /// Barın altındaki ince ayırıcı çizgi görünsün mü
    var showsDivider: Bool?
    /// Bar uzatılınca başlığın dikey yeri; yatay yeri `textAlignment`'ta durur.
    var verticalAlignment: VerticalAlign?

    // MARK: - Ortak görünüm (buton, metin kutusu, anahtar, metin, üst bar)

    /// Ana renk, hex olarak: "#AC5135". Butonda dolgu, metin kutusunda kenarlık ve ikon,
    /// anahtarda açıkken rengi, kaydırıcıda dolu kısım, üst barda arka plan.
    var fillColor: String?
    /// Yazı rengi, hex olarak. Butonda sadece dolu stilde kullanılır; metinde yazının kendisi,
    /// üst barda başlık.
    var contentColor: String?
    /// İkonun yeri; hangi ikon olduğu `symbolName`'de durur.
    var iconPosition: IconPosition?

    // MARK: - Metin kutusu görünümü

    var border: TextFieldBorder?
    var inputKind: TextFieldKind?

    // MARK: - Anahtar görünümü

    var labelPosition: SwitchLabelPosition?

    // MARK: - Kaydırıcı görünümü

    /// Çubuğun iki ucundaki ikonlar görünsün mü; ikonlar `minSymbolName` ve `maxSymbolName`'de.
    var showsSideIcons: Bool?
    /// Alt değer tarafındaki (sol) ikon
    var minSymbolName: String?
    /// Üst değer tarafındaki (sağ) ikon
    var maxSymbolName: String?
    /// Değer çubuğun sağında yazıyla gösterilsin mi
    var showsValue: Bool?

    // MARK: - Alt menü görünümü
    // Arka plan `fillColor`, seçili sekme `tintColor`, diğer sekmeler `contentColor`,
    // üstteki ince çizgi `showsDivider`'da durur.

    /// Sekmelerin altında yazıları görünsün mü; kapalıysa sadece ikonlar.
    var showsLabels: Bool?
    /// Köşeli bar klasik alt menü gibi çizilir; yuvarlak ya da hap bar iOS 26'daki yüzen alt menü gibi.
    var tabBarCorner: TabBarCorner?
    /// Arka plan saydam mı: arkadaki içerik bulanık görünür (cam görünüm).
    var isTranslucent: Bool?
}
