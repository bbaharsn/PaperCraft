//
//  ElementAction.swift
//  PaperCraft
//

import Foundation

/// Önizlemede bir elemana dokununca ne olacağı.
nonisolated enum ElementAction: Codable, Equatable, Hashable {
    case none
    /// Bir önceki sayfaya döner.
    case back
    /// Projedeki başka bir sayfayı açar.
    case goTo(screenID: UUID)
}
