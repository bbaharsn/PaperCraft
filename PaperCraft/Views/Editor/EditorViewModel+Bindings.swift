//
//  EditorViewModel+Bindings.swift
//  PaperCraft
//

import SwiftUI

/// Özellikler sayfalarının seçili elemana bağlanmak için kullandığı ortak `Binding`'ler.
/// Her sayfada tekrar yazılmasın diye burada.
extension EditorViewModel {

    /// Seçili elemanın bir özelliğine bağlanan `Binding`.
    /// Özellik boşsa (`nil`) `default` değeri gösterilir; değiştirince modele yazılır.
    func binding<Value>(_ keyPath: WritableKeyPath<ElementProperties, Value?>,
                        default defaultValue: Value) -> Binding<Value> {
        Binding(
            get: { self.selectedElement?.properties[keyPath: keyPath] ?? defaultValue },
            set: { newValue in self.updateSelectedProperties { $0[keyPath: keyPath] = newValue } }
        )
    }

    /// Seçili alt menüdeki bir sekmenin yazısına ya da ikonuna bağlanan `Binding`.
    func tabBinding(at index: Int, _ keyPath: WritableKeyPath<TabItem, String>) -> Binding<String> {
        Binding(
            get: {
                guard let items = self.selectedElement?.properties.items, items.indices.contains(index) else { return "" }
                return items[index][keyPath: keyPath]
            },
            set: { newValue in self.updateSelectedTab(at: index) { $0[keyPath: keyPath] = newValue } }
        )
    }

    /// Seçili elemanın genişliğine ya da yüksekliğine (point) bağlanan `Binding`.
    func sizeBinding(_ keyPath: KeyPath<CGSize, CGFloat>) -> Binding<Double> {
        Binding(
            get: {
                guard let element = self.selectedElement else { return 0 }
                return Double(self.pointRect(of: element).size[keyPath: keyPath].rounded())
            },
            set: { newValue in
                guard let element = self.selectedElement else { return }
                var size = self.pointRect(of: element).size
                if keyPath == \CGSize.width { size.width = newValue } else { size.height = newValue }
                self.setSelectedSize(width: size.width, height: size.height)
            }
        )
    }
}
