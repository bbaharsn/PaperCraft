//
//  PhoneStatusBar.swift
//  PaperCraft
//

import SwiftUI

/// Telefon çerçevesindeki sahte durum çubuğu: saat, Dynamic Island, sinyal, Wi-Fi ve pil.
/// iPhone 15/16'nın ölçüleriyle tuval point'inde çizilir (393 × 59); önizleme çerçeveyle birlikte ölçekler.
/// Yazı rengi arkasındaki renge göre siyah ya da beyazdır; gerçek iPhone'daki gibi.
struct PhoneStatusBar: View {
    /// Durum çubuğunun arkasındaki renk (üst bar ya da sayfa arka planı).
    let background: Color

    @Environment(\.self) private var environment

    var body: some View {
        HStack(spacing: 0) {
            // Saat sol yarının ortasında durur
            TimelineView(.everyMinute) { context in
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 17, weight: .semibold))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)

            Capsule()
                .fill(.black)
                .frame(width: 126, height: 37)

            HStack(spacing: 6) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
                    .font(.system(size: 17, weight: .regular))
            }
            .font(.system(size: 15, weight: .semibold))
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(foreground)
        .padding(.top, 11)
        .frame(height: PreviewLayout.phoneTopInset, alignment: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Koyu arkada beyaz, açık arkada siyah.
    private var foreground: Color {
        let resolved = background.resolve(in: environment)
        let luminance = 0.2126 * resolved.red + 0.7152 * resolved.green + 0.0722 * resolved.blue
        return luminance < 0.5 ? .white : .black
    }
}
