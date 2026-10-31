//
//  Project.swift
//  PaperCraft
//

import Foundation
import SwiftData

/// Kullanıcının bir prototipi: adı ve ekranları. "Projelerim" ekranında listelenir.
/// iCloud kuralı: tüm alanlar varsayılan değerli, `unique` yok, ilişki opsiyonel.
@Model
final class Project {
    var name: String = "Yeni Proje"
    var createdAt = Date.now
    /// Son değişiklik zamanı; Projelerim'de en son düzenlenen en üstte görünür.
    var updatedAt = Date.now
    /// Proje silinince ekranları da silinir.
    @Relationship(deleteRule: .cascade, inverse: \ScreenRecord.project)
    var screens: [ScreenRecord]? = []

    init(name: String) {
        self.name = name
    }

    /// Yeni bir projeyi tek ekranıyla birlikte veritabanına ekler.
    /// İlişki, proje veritabanına eklendikten sonra kurulur (SwiftData bunu ister).
    @discardableResult
    static func create(name: String, screen: PrototypeScreen, in context: ModelContext) -> Project {
        let project = Project(name: name)
        context.insert(project)
        project.screens?.append(ScreenRecord(screen: screen, order: 0))
        return project
    }

    /// Diğer projelerle çakışmayan bir ad: "Yeni Proje", "Yeni Proje 2", "Yeni Proje 3"…
    static func uniqueName(_ base: String, existing: [String]) -> String {
        guard existing.contains(base) else { return base }
        var number = 2
        while existing.contains("\(base) \(number)") { number += 1 }
        return "\(base) \(number)"
    }

    /// Tüm projelerde kullanılan fotoğrafların dosya adları.
    /// Bir kayıt bile okunamazsa `nil`: içindeki adları bilemeyiz, temizlik o fotoğrafları silmesin.
    static func uploadedImageNames(in projects: [Project]) -> Set<String>? {
        var names: Set<String> = []
        for record in projects.flatMap(\.sortedScreens) {
            guard let screen = record.screen else { return nil }
            names.formUnion(screen.uploadedImageNames)
        }
        return names
    }

    /// Ekran kayıtları, sırasıyla.
    var sortedScreens: [ScreenRecord] {
        (screens ?? []).sorted { $0.order < $1.order }
    }

    /// Projelerim kartında görünen ilk ekran. Kayıt yoksa ya da bozuksa boş bir ekran.
    var firstScreen: PrototypeScreen {
        sortedScreens.first?.screen ?? PrototypeScreen(name: "Sayfa 1")
    }

    /// Tüm sayfalar, sırasıyla; önizleme bunların kopyasıyla çalışır. Bozuk kayıt boş sayfa olur.
    var previewScreens: [PrototypeScreen] {
        sortedScreens.map { $0.screen ?? PrototypeScreen(name: "Sayfa") }
    }

    /// Sona boş bir sayfa ekler: "Sayfa 2", "Sayfa 3"…
    @discardableResult
    func addScreen() -> ScreenRecord {
        let names = previewScreens.map(\.name)
        var number = sortedScreens.count + 1
        while names.contains("Sayfa \(number)") { number += 1 }
        let record = ScreenRecord(screen: PrototypeScreen(name: "Sayfa \(number)"),
                                  order: (sortedScreens.last?.order ?? -1) + 1)
        screens?.append(record)
        updatedAt = .now
        return record
    }

    /// Editördeki değişikliği sayfanın kaydına yazar ve son değişiklik zamanını günceller.
    func save(_ screen: PrototypeScreen, to record: ScreenRecord) {
        record.update(screen)
        updatedAt = .now
    }

    /// Boş ad kaydedilmez; eski ad kalır.
    func renameScreen(_ record: ScreenRecord, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, var screen = record.screen else { return }
        screen.name = trimmed
        save(screen, to: record)
    }

    /// Sayfayı siler, ona giden buton bağlantılarını kaldırır. Son sayfa silinmez.
    func deleteScreen(_ record: ScreenRecord, in context: ModelContext) {
        guard sortedScreens.count > 1 else { return }
        let deletedID = record.screen?.id
        screens?.removeAll { $0 === record }
        context.delete(record)
        if let deletedID {
            for other in sortedScreens {
                guard var screen = other.screen else { continue }
                screen.removeLinks(to: deletedID)
                other.update(screen)
            }
        }
        updatedAt = .now
    }
}
