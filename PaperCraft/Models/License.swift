//
//  License.swift
//  PaperCraft
//

import Foundation

/// Uygulamada kullanılan bir açık kaynak parçası ve lisans metni (`Resources/Licenses`).
struct License: Identifiable, Hashable {
    /// Ekranda görünen ad, ör. "Fluent Emoji"
    let name: String
    /// Neyde kullanıldığı ve lisans türü
    let detail: String
    /// Lisans dosyasının adı (uzantısız, `.txt`)
    let fileName: String

    var id: String { fileName }

    /// Uygulamadaki tüm lisanslar. Yeni bir kaynak eklenince buraya da eklenir.
    static let all: [License] = [
        License(name: "Fluent Emoji", detail: "Microsoft · Görsel kütüphanesi · MIT",
                fileName: "FluentEmoji-LICENSE"),
        License(name: "Bricolage Grotesque", detail: "Logo yazı tipi · SIL Open Font License 1.1",
                fileName: "BricolageGrotesque-OFL"),
    ]

    /// Lisans metni; dosya bulunamazsa `nil`.
    func text(in bundle: Bundle = .main) -> String? {
        guard let url = bundle.url(forResource: fileName, withExtension: "txt") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
