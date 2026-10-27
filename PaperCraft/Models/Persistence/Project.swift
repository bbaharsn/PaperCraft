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

    /// Editörün açtığı ekran (şimdilik projede tek ekran var). Kayıt yoksa ya da bozuksa boş bir ekran.
    var firstScreen: PrototypeScreen {
        sortedScreens.first?.screen ?? PrototypeScreen(name: "Ekran 1")
    }

    /// Editördeki değişikliği ilk ekrana yazar ve son değişiklik zamanını günceller.
    func saveFirstScreen(_ screen: PrototypeScreen) {
        if let record = sortedScreens.first {
            record.update(screen)
        } else {
            screens?.append(ScreenRecord(screen: screen, order: 0))
        }
        updatedAt = .now
    }
}
