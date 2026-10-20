//
//  ElementProperties+Slider.swift
//  PaperCraft
//

import Foundation

extension ElementProperties {
    /// Kaydırıcının aralığı. Değerler ters ya da eşit gelirse (ör. AI'dan) çökmesin diye düzeltilir:
    /// küçük olan alt sınır olur, eşitse üst sınır bir fazlası alınır.
    nonisolated var sliderRange: ClosedRange<Double> {
        let first = minValue ?? 0
        let second = maxValue ?? 1
        let lower = min(first, second)
        let upper = max(first, second)
        return lower...(upper > lower ? upper : lower + 1)
    }

    /// Aralığın içine sıkıştırılmış değer.
    nonisolated var sliderValue: Double {
        min(max(value ?? 0.5, sliderRange.lowerBound), sliderRange.upperBound)
    }
}
