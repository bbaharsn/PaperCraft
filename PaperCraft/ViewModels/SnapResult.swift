//
//  SnapResult.swift
//  PaperCraft
//

import CoreGraphics

/// Yapışma hesabının sonucu: elemanın ham konumuna eklenecek düzeltme ve çizilecek çizgiler.
nonisolated struct SnapResult: Equatable {
    var offset: CGSize = .zero
    var guides: [SnapGuide] = []
}
