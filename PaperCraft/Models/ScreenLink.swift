//
//  ScreenLink.swift
//  PaperCraft
//

import Foundation

/// "Dokununca" listesinde seçilebilen bir sayfa.
nonisolated struct ScreenLink: Identifiable, Equatable {
    let id: UUID
    let name: String
}
