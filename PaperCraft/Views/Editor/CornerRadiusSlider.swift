//
//  CornerRadiusSlider.swift
//  PaperCraft
//

import SwiftUI

/// Seçili elemanın köşe yuvarlaklığı (`cornerRadius`). En uçta kısa kenarın yarısıdır:
/// kare eleman daire, uzun eleman hap olur. Kutu ve görsel kullanır.
struct CornerRadiusSlider: View {
    let viewModel: EditorViewModel
    /// Alan boşken kullanılan değer (kutuda 12, görselde 0).
    let defaultRadius: Double

    /// Kısa kenarın yarısı: daha fazlası görünümü değiştirmez.
    private var maxRadius: Double {
        guard let element = viewModel.selectedElement else { return 60 }
        let size = viewModel.pointRect(of: element).size
        return max(min(size.width, size.height) / 2, 1)
    }

    var body: some View {
        Slider(value: radiusBinding, in: 0...maxRadius)
            .tint(Theme.ink)
    }

    /// Kaydırıcı en uçtayken saklanan değer de o uca iner.
    private var radiusBinding: Binding<Double> {
        let stored = viewModel.binding(\.cornerRadius, default: defaultRadius)
        return Binding(
            get: { min(stored.wrappedValue, maxRadius) },
            set: { stored.wrappedValue = $0.rounded() }
        )
    }
}
