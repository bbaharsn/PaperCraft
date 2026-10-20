//
//  ResizeCorner.swift
//  PaperCraft
//

import Foundation

/// Seçili elemanın boyutunu değiştirmek için tutulabilen dört köşe.
nonisolated enum ResizeCorner: CaseIterable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    /// Sol taraftaki köşelerden mi?
    var isLeading: Bool { self == .topLeading || self == .bottomLeading }
    /// Üst taraftaki köşelerden mi?
    var isTop: Bool { self == .topLeading || self == .topTrailing }
}
