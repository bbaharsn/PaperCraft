//
//  PanelPage.swift
//  PaperCraft
//

import SwiftUI

/// iPad panelindeki bir alt sayfa: başlığı ve içeriği. `PanelNavigator` yığınında durur.
struct PanelPage: Identifiable {
    let id = UUID()
    let title: String
    let content: AnyView
}
