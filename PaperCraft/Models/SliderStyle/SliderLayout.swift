//
//  SliderLayout.swift
//  PaperCraft
//

import CoreGraphics

/// Kaydırıcının çubuk dışındaki parçalarının kapladığı genişlikler (point).
/// Canvas çizimi ve çerçeveyi genişleten `EditorViewModel` aynı değerleri kullanır;
/// böylece ikon/değer açılınca çubuğun kendisi kısalmaz.
nonisolated enum SliderLayout {
    /// Parçalar ile çubuk arasındaki boşluk
    static let spacing: CGFloat = 8
    /// Yan ikonlardan birinin genişliği
    static let iconWidth: CGFloat = 24
    /// Değer yazısının genişliği
    static let valueWidth: CGFloat = 44

    /// Açık parçaların çubuğa eklediği toplam genişlik.
    static func extraWidth(for properties: ElementProperties) -> CGFloat {
        var width: CGFloat = 0
        if properties.showsSideIcons ?? false { width += 2 * (iconWidth + spacing) }
        if properties.showsValue ?? false { width += valueWidth + spacing }
        return width
    }
}
