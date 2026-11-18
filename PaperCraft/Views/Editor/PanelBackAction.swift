//
//  PanelBackAction.swift
//  PaperCraft
//

import SwiftUI

/// Alt sayfayı kapatır: panelde yığından çıkarır, iPhone sayfasında geri döner.
/// `dismiss()` panelde editörün kendisini kapatırdı; alt sayfalar bunu kullanır.
struct PanelBackAction {
    let panel: PanelNavigator?
    let dismiss: DismissAction

    func callAsFunction() {
        if let panel {
            withAnimation(.snappy) { panel.pop() }
        } else {
            dismiss()
        }
    }
}
