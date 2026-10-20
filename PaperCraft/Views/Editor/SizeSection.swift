//
//  SizeSection.swift
//  PaperCraft
//

import SwiftUI

/// Özellikler sayfalarındaki "Boyut" bölümü: genişlik × yükseklik (point).
struct SizeSection: View {
    let viewModel: EditorViewModel

    var body: some View {
        Section("Boyut") {
            HStack {
                sizeField("Genişlik", value: viewModel.sizeBinding(\.width))
                Text("×").foregroundStyle(.secondary)
                sizeField("Yükseklik", value: viewModel.sizeBinding(\.height))
            }
        }
    }

    /// Küçük başlıklı sayı kutusu. Değer "Bitti"ye (return) basınca uygulanır.
    private func sizeField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number.precision(.fractionLength(0)))
                #if os(iOS)
                .keyboardType(.numbersAndPunctuation)
                #endif
                .submitLabel(.done)
        }
    }
}
