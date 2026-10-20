//
//  SwitchElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki bir anahtarı etiketi, açık/kapalı durumu ve renkleriyle çizer.
/// Prototipte dokunulamaz; durum Özellikler sayfasından değişir.
struct SwitchElementView: View {
    let properties: ElementProperties

    private var labelPosition: SwitchLabelPosition { properties.labelPosition ?? .leading }
    private var label: String { properties.text ?? "" }

    /// Anahtarın açıkken rengi
    private var tintColor: Color {
        properties.fillColor.flatMap(Color.init(hexString:)) ?? .green
    }

    /// Etiketin rengi
    private var textColor: Color {
        properties.contentColor.flatMap(Color.init(hexString:)) ?? .primary
    }

    var body: some View {
        HStack(spacing: 8) {
            if labelPosition == .trailing { toggle }
            // Etiket boşsa yer kaplamasın; anahtar yine aynı kenarda kalır
            Text(label)
                .foregroundStyle(textColor)
                .lineLimit(1)
                // Etiket hep anahtardan uzak kenara yaslanır
                .frame(maxWidth: .infinity,
                       alignment: labelPosition == .leading ? .leading : .trailing)
            if labelPosition == .leading { toggle }
        }
        .font(.system(size: 17))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toggle: some View {
        Toggle("", isOn: .constant(properties.isOn ?? false))
            .labelsHidden()
            .toggleStyle(.switch)   // macOS'ta varsayılan onay kutusu olmasın
            .tint(tintColor)
    }
}

#Preview {
    let samples: [ElementProperties] = [
        ElementProperties(text: "Bildirimler", isOn: true, fillColor: "#34C759", labelPosition: .leading),
        ElementProperties(text: "Karanlık mod", isOn: false, labelPosition: .trailing),
        ElementProperties(text: "", isOn: true, fillColor: "#AC5135"),
    ]
    VStack(spacing: 20) {
        ForEach(samples.indices, id: \.self) { index in
            SwitchElementView(properties: samples[index])
                .frame(width: 300, height: 44)
        }
    }
    .padding()
    .background(Theme.paper)
}
