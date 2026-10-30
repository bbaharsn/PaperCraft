//
//  TextFieldElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki bir metin kutusunu kenarlığı, renkleri ve ikonuyla çizer.
/// Canvas'ta ipucu metni (placeholder) gösterilir; önizlemede `interactive` verilir ve gerçekten yazılır.
struct TextFieldElementView: View {
    let properties: ElementProperties
    /// Önizlemede elemanın değiştirilebilir kopyası; yazılan metin `text`'e gider. Canvas'ta `nil`.
    var interactive: Binding<ElementProperties>? = nil

    /// Köşe yarıçapı; seçim çizgisi de aynı değeri kullansın diye butonla ortak.
    static let cornerRadius = ButtonShape.roundedCornerRadius

    private var border: TextFieldBorder { properties.border ?? .roundedBorder }
    private var iconPosition: IconPosition { properties.iconPosition ?? .none }

    /// Kenarlık ve ikon rengi
    private var accentColor: Color {
        properties.fillColor.flatMap(Color.init(hexString:)) ?? .gray
    }

    /// Yazı rengi; ipucu metni bunun soluk hali.
    private var textColor: Color {
        properties.contentColor.flatMap(Color.init(hexString:)) ?? .primary
    }

    var body: some View {
        HStack(spacing: 8) {
            if iconPosition == .leading { icon }
            if let interactive {
                input(interactive)
            } else {
                Text(properties.placeholder ?? "")
                    .foregroundStyle(textColor.opacity(0.4))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            if iconPosition == .trailing { icon }
        }
        .font(.system(size: 17))
        .padding(.horizontal, border == .underline || border == .none ? 4 : 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { background }
    }

    /// Önizlemedeki gerçek metin kutusu; şifre türünde yazılanlar gizlenir.
    @ViewBuilder
    private func input(_ interactive: Binding<ElementProperties>) -> some View {
        let text = Binding(get: { interactive.wrappedValue.text ?? "" },
                           set: { interactive.wrappedValue.text = $0 })
        let prompt = Text(properties.placeholder ?? "").foregroundStyle(textColor.opacity(0.4))
        Group {
            if properties.inputKind == .secure {
                SecureField("", text: text, prompt: prompt)
            } else {
                TextField("", text: text, prompt: prompt)
                    #if os(iOS)
                    .keyboardType(properties.inputKind == .email ? .emailAddress : .default)
                    .textInputAutocapitalization(properties.inputKind == .email ? .never : .sentences)
                    #endif
            }
        }
        .textFieldStyle(.plain)
        .foregroundStyle(textColor)
    }

    private var icon: some View {
        Image(systemName: properties.symbolName ?? "magnifyingglass")
            .foregroundStyle(accentColor)
    }

    @ViewBuilder
    private var background: some View {
        switch border {
        case .roundedBorder:
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(.white)
                .overlay(RoundedRectangle(cornerRadius: Self.cornerRadius).stroke(accentColor, lineWidth: 1))
        case .capsule:
            Capsule()
                .fill(.white)
                .overlay(Capsule().stroke(accentColor, lineWidth: 1))
        case .underline:
            VStack {
                Spacer()
                Rectangle().fill(accentColor).frame(height: 1.5)
            }
        case .none:
            Color.clear
        }
    }
}

#Preview {
    let samples: [ElementProperties] = [
        ElementProperties(placeholder: "E-posta", symbolName: "envelope",
                          fillColor: "#C7C7CC", iconPosition: .leading, border: .roundedBorder),
        ElementProperties(placeholder: "Ara", symbolName: "magnifyingglass",
                          fillColor: "#007AFF", iconPosition: .leading, border: .capsule),
        ElementProperties(placeholder: "Şifre", symbolName: "eye",
                          fillColor: "#AC5135", iconPosition: .trailing, border: .underline, inputKind: .secure),
        ElementProperties(placeholder: "Not", border: TextFieldBorder.none),
    ]
    VStack(spacing: 20) {
        ForEach(samples.indices, id: \.self) { index in
            TextFieldElementView(properties: samples[index])
                .frame(width: 300, height: 44)
        }
    }
    .padding()
    .background(Theme.paper)
}
