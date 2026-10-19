//
//  ComponentCatalog.swift
//  PaperCraft
//

import Foundation

/// `ComponentCatalog.json` dosyasının Swift karşılığı.
/// Hangi bileşenlerin var olduğunu bilir ve onlardan yeni elemanlar üretir.
nonisolated struct ComponentCatalog: Decodable {
    let schemaVersion: Int
    let referenceCanvas: CatalogSize
    let components: [ComponentDefinition]

    enum LoadError: Error {
        case fileNotFound
    }

    /// Kataloğu uygulama paketinden (bundle) okur.
    static func load(from bundle: Bundle = .main) throws -> ComponentCatalog {
        guard let url = bundle.url(forResource: "ComponentCatalog", withExtension: "json") else {
            throw LoadError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ComponentCatalog.self, from: data)
    }

    /// Katalog dosyası okunamadığında kullanılan boş katalog (uygulama çökmesin diye).
    static let empty = ComponentCatalog(
        schemaVersion: 1,
        referenceCanvas: CatalogSize(width: 393, height: 852),
        components: []
    )

    /// Kategoriler, JSON'daki ilk görünme sırasıyla ve tekrarsız: ["Temel", "Form", ...]
    var categories: [String] {
        var result: [String] = []
        for component in components where !result.contains(component.category) {
            result.append(component.category)
        }
        return result
    }

    /// Bir kategorideki bileşenler, JSON'daki sırasıyla.
    func components(in category: String) -> [ComponentDefinition] {
        components.filter { $0.category == category }
    }

    /// Verilen türün katalogdaki tanımını döndürür; yoksa `nil`.
    func definition(for type: ElementType) -> ComponentDefinition? {
        components.first { $0.type == type }
    }

    /// Katalogdaki varsayılan değerlerle yeni bir eleman üretir.
    /// Tür katalogda yoksa (ör. `.unknown`) `nil` döner.
    func makeElement(of type: ElementType) -> CanvasElement? {
        guard let definition = definition(for: type) else { return nil }

        // Point → normalize (0...1) dönüşümü
        let width = definition.defaultSize.width / referenceCanvas.width
        let height = definition.defaultSize.height / referenceCanvas.height

        // Yatayda her zaman ortala; dikey konum yerleşim kuralına bağlı.
        let x = (1 - width) / 2
        let y: Double
        switch definition.placement {
        case .top:
            y = 0
        case .bottom:
            y = 1 - height
        case .free:
            y = (1 - height) / 2
        }

        return CanvasElement(
            type: type,
            frame: NormalizedFrame(x: x, y: y, width: width, height: height),
            properties: definition.defaultProperties
        )
    }
}
