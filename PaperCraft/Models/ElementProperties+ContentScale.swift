//
//  ElementProperties+ContentScale.swift
//  PaperCraft
//

import CoreGraphics

extension ElementProperties {
    /// Çizimde kullanılan çarpan; boşsa 1.
    var scale: CGFloat { CGFloat(contentScale ?? 1) }

    /// Çarpanı `factor` kadar büyütür/küçültür. Aşırı değerlere kaçmasın diye sınırlıdır.
    mutating func scaleContent(by factor: Double) {
        let scaled = (contentScale ?? 1) * factor
        contentScale = min(max(scaled, 0.1), 20)
    }
}
