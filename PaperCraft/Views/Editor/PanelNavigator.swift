//
//  PanelNavigator.swift
//  PaperCraft
//

import SwiftUI

/// iPad'deki sabit panelin kendi küçük sayfa yığını (font listesi, sekme düzenleme…).
/// Panel editörün `NavigationStack`'inin içinde durduğu için `NavigationLink` editörün yerine açılıyordu;
/// alt sayfalar bunun yerine bu yığına eklenir ve panelin içinde görünür.
@Observable
final class PanelNavigator {
    /// Açık alt sayfalar; sondaki görünür. Boşsa panelin ana içeriği görünür.
    private(set) var pages: [PanelPage] = []

    var top: PanelPage? { pages.last }

    func push(_ page: PanelPage) {
        pages.append(page)
    }

    func pop() {
        _ = pages.popLast()
    }
}

extension EnvironmentValues {
    /// Panelin içindeyken dolu; iPhone'daki alttan açılan sayfada `nil`.
    @Entry var panelNavigator: PanelNavigator?
}
