//
//  PrototypeScreen.swift
//  PaperCraft
//

import Foundation

/// Bir prototipteki tek bir ekran.
/// `elements` dizisindeki sıra çizim sırasıdır: sondaki eleman en üstte görünür.
nonisolated struct PrototypeScreen: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var elements: [CanvasElement] = []

    /// Ekrandaki yüklenmiş fotoğrafların dosya adları; çoğaltılan elemanlar aynı adı paylaşır, bir kez sayılır.
    var uploadedImageNames: Set<String> {
        Set(elements.compactMap(\.properties.uploadedImageName))
    }

    /// Verilen elemanın özelliklerini değiştirir; eleman yoksa hiçbir şey olmaz.
    /// Önizleme bunu ekranın kendi kopyasında kullanır (switch'i açmak, yazı yazmak…).
    mutating func updateProperties(of id: UUID, _ change: (inout ElementProperties) -> Void) {
        guard let index = elements.firstIndex(where: { $0.id == id }) else { return }
        change(&elements[index].properties)
    }

    /// Silinen bir sayfaya giden buton, görsel ve sekme bağlantılarını kaldırır.
    mutating func removeLinks(to screenID: UUID) {
        let link = ElementAction.goTo(screenID: screenID)
        for index in elements.indices {
            if elements[index].properties.action == link {
                elements[index].properties.action = ElementAction.none
            }
            guard let items = elements[index].properties.items else { continue }
            elements[index].properties.items = items.map { item in
                var item = item
                if item.action == link { item.action = ElementAction.none }
                return item
            }
        }
    }
}
