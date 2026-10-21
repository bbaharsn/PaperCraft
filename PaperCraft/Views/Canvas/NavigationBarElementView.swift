//
//  NavigationBarElementView.swift
//  PaperCraft
//

import SwiftUI

/// Canvas'taki üst barı başlığı, geri butonu, sağ butonu ve renkleriyle çizer.
/// Küçük başlıkta her şey tek satırda ve satır dikey konuma göre kayar;
/// büyük başlıkta butonlar üstte kalır, başlık altlarındaki alanda konumlanır.
struct NavigationBarElementView: View {
    let properties: ElementProperties

    private var mode: NavigationTitleMode { properties.titleDisplayMode ?? .inline }
    private var title: String { properties.text ?? "" }
    private var alignment: TextAlign { properties.textAlignment ?? mode.defaultAlignment }
    private var verticalAlignment: VerticalAlign { properties.verticalAlignment ?? mode.defaultVerticalAlignment }

    private var backgroundColor: Color {
        properties.fillColor.flatMap(Color.init(hexString:)) ?? Color(white: 0.98)
    }

    private var titleColor: Color {
        properties.contentColor.flatMap(Color.init(hexString:)) ?? .primary
    }

    private var tintColor: Color {
        properties.tintColor.flatMap(Color.init(hexString:)) ?? .blue
    }

    private var showsBackButton: Bool { properties.showsBackButton ?? false }

    private var hasButtons: Bool {
        showsBackButton || (properties.trailingItem ?? .none) != .none
    }

    /// Başlık, Metin elemanındaki aynı yazı tipi listesinden seçilir.
    private func titleFont(_ style: TextFontStyle) -> Font {
        TextElementView.font(named: properties.fontName, style: style)
    }

    private var horizontal: HorizontalAlignment {
        switch alignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    private var vertical: VerticalAlignment {
        switch verticalAlignment {
        case .top: .top
        case .center: .center
        case .bottom: .bottom
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            switch mode {
            case .inline:
                inlineRow
                    .frame(height: NavigationTitleMode.inline.barHeight)
                    .frame(maxHeight: .infinity, alignment: Alignment(horizontal: .center, vertical: vertical))
            case .large:
                HStack {
                    if showsBackButton { backButton }
                    Spacer()
                    trailingButton
                }
                .padding(.horizontal, 8)
                .frame(height: NavigationTitleMode.inline.barHeight)

                Text(title)
                    .font(titleFont(.largeTitle))
                    .fontWeight(.bold)
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
                    // Uzun başlık kesilmek yerine sığana kadar küçülür
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: Alignment(horizontal: horizontal, vertical: vertical))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .overlay(alignment: .bottom) {
            if properties.showsDivider ?? true {
                Rectangle()
                    .fill(.black.opacity(0.2))
                    .frame(height: 0.5)
            }
        }
    }

    /// Küçük başlıkta tek satır: geri butonu, başlık ve sağ buton.
    /// Ortadaki başlık butonlardan bağımsız tam ortada durur; sola/sağa yaslı başlık butonların yanına gelir.
    @ViewBuilder
    private var inlineRow: some View {
        switch alignment {
        case .center:
            ZStack {
                inlineTitle
                    // Butonlarla çakışmasın diye pay sadece buton varken bırakılır
                    .padding(.horizontal, hasButtons ? 88 : 16)
                HStack {
                    if showsBackButton { backButton }
                    Spacer()
                    trailingButton
                }
                .padding(.horizontal, 8)
            }
        case .leading:
            HStack(spacing: 8) {
                if showsBackButton { backButton }
                inlineTitle.padding(.leading, showsBackButton ? 0 : 8)
                Spacer(minLength: 8)
                trailingButton
            }
            .padding(.horizontal, 8)
        case .trailing:
            HStack(spacing: 8) {
                if showsBackButton { backButton }
                Spacer(minLength: 8)
                inlineTitle.padding(.trailing, (properties.trailingItem ?? .none) == .none ? 8 : 0)
                trailingButton
            }
            .padding(.horizontal, 8)
        }
    }

    private var inlineTitle: some View {
        Text(title)
            .font(titleFont(.headline))
            .fontWeight(.semibold)
            .foregroundStyle(titleColor)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private var backButton: some View {
        HStack(spacing: 4) {
            Image(systemName: "chevron.left")
                .fontWeight(.semibold)
            Text(properties.backTitle ?? "")
        }
        .font(.body)
        .foregroundStyle(tintColor)
    }

    @ViewBuilder
    private var trailingButton: some View {
        switch properties.trailingItem ?? .none {
        case .none:
            EmptyView()
        case .icon:
            Image(systemName: properties.symbolName ?? "plus")
                .font(.body.weight(.medium))
                .foregroundStyle(tintColor)
                .padding(.horizontal, 8)
        case .text:
            Text(properties.trailingText ?? "")
                .font(.body)
                .foregroundStyle(tintColor)
                .padding(.horizontal, 8)
        }
    }
}

#Preview {
    let samples: [ElementProperties] = [
        ElementProperties(text: "Ayarlar", titleDisplayMode: .inline, showsBackButton: true, backTitle: "Geri",
                          trailingItem: .icon, tintColor: "#007AFF", showsDivider: true),
        ElementProperties(text: "Notlar", symbolName: "square.and.arrow.up", titleDisplayMode: .large,
                          showsBackButton: true, backTitle: "", trailingItem: .text, trailingText: "Düzenle",
                          tintColor: "#AC5135"),
    ]
    VStack(spacing: 20) {
        ForEach(samples.indices, id: \.self) { index in
            NavigationBarElementView(properties: samples[index])
                .frame(width: 393, height: samples[index].titleDisplayMode?.barHeight ?? 44)
        }
    }
    .padding()
    .background(Theme.paper)
}
