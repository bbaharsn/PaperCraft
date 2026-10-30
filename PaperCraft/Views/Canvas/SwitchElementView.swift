//
//  SwitchElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki bir anahtarı etiketi, açık/kapalı durumu ve renkleriyle çizer.
/// Canvas'ta dokunulamaz; durum Özellikler sayfasından değişir. Önizlemede `interactive` verilir ve açılıp kapanır.
struct SwitchElementView: View {
    let properties: ElementProperties
    /// Önizlemede elemanın değiştirilebilir kopyası; canvas'ta `nil`.
    var interactive: Binding<ElementProperties>? = nil

    private var isOn: Binding<Bool> {
        guard let interactive else { return .constant(properties.isOn ?? false) }
        return Binding(get: { interactive.wrappedValue.isOn ?? false },
                       set: { interactive.wrappedValue.isOn = $0 })
    }

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
        Toggle("", isOn: isOn)
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
