//
//  ScreenRecord.swift
//  PaperCraft
//

import Foundation
import SwiftData

/// Bir projedeki tek bir ekranın kaydı. Ekranın kendisi (ad ve elemanlar) JSON olarak `data`'da durur;
/// böylece eleman yapısı değişse de veritabanı şeması değişmez ve iCloud ile daha az sorun çıkar.
/// iCloud kuralı: tüm alanlar varsayılan değerli, ilişki opsiyonel.
@Model
final class ScreenRecord {
    /// Projedeki sırası (0 ilk ekran).
    var order: Int = 0
    /// `PrototypeScreen`'in JSON hali.
    var data = Data()
    /// JSON biçiminin sürümü; biçim değişirse eski kayıtları dönüştürmek için.
    var schemaVersion: Int = 1
    var project: Project?

    init(screen: PrototypeScreen, order: Int) {
        self.order = order
        update(screen)
    }

    /// Kayıttaki ekran; veri bozuksa `nil`.
    var screen: PrototypeScreen? {
        try? JSONDecoder().decode(PrototypeScreen.self, from: data)
    }

    /// Ekranın yeni halini kayda yazar.
    func update(_ screen: PrototypeScreen) {
        guard let encoded = try? JSONEncoder().encode(screen) else { return }
        data = encoded
    }
}
