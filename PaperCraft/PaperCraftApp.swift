//
//  PaperCraftApp.swift
//  PaperCraft
//
//  Created by Bahar Şen on 13.10.2026.
//

import SwiftData
import SwiftUI

@main
struct PaperCraftApp: App {
    init() {
        FontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ProjectsView()
        }
        // Projeler cihazda SwiftData ile saklanır; değişiklikler kendiliğinden kaydedilir.
        .modelContainer(for: [Project.self, ScreenRecord.self])
    }
}
