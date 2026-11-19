//
//  DeviceStatusBar.swift
//  PaperCraft
//

import SwiftUI

/// Cihaz çerçevesindeki sahte durum çubuğu. Tuval point'inde çizilir; önizleme çerçeveyle birlikte ölçekler.
/// - iPhone (393 × 59): saat, Dynamic Island, sinyal, Wi-Fi ve pil.
/// - iPad (24 pt): solda saat, sağda Wi-Fi ve pil; ada yok.
/// Yazı rengi arkasındaki renge göre siyah ya da beyazdır; gerçek cihazdaki gibi.
struct DeviceStatusBar: View {
    /// Durum çubuğunun arkasındaki renk (üst bar ya da sayfa arka planı).
    let background: Color
    /// iPhone mu, iPad mi?
    let isPhone: Bool

    @Environment(\.self) private var environment

    var body: some View {
        Group {
            if isPhone { phoneBar } else { tabletBar }
        }
        .foregroundStyle(foreground)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var phoneBar: some View {
        HStack(spacing: 0) {
            // Saat sol yarının ortasında durur
            clock.font(.system(size: 17, weight: .semibold))
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
        .padding(.top, 11)
        .frame(height: 59, alignment: .top)
    }

    private var tabletBar: some View {
        HStack(spacing: 6) {
            clock
            Spacer()
            Image(systemName: "wifi")
            Image(systemName: "battery.100")
                .font(.system(size: 14, weight: .regular))
        }
        .font(.system(size: 12, weight: .semibold))
        .padding(.horizontal, 20)
        .frame(height: 24)
    }

    /// Cihazın gerçek saati; her dakika yenilenir.
    private var clock: some View {
        TimelineView(.everyMinute) { context in
            Text(context.date, format: .dateTime.hour().minute())
                .monospacedDigit()
        }
    }

    /// Koyu arkada beyaz, açık arkada siyah.
    private var foreground: Color {
        let resolved = background.resolve(in: environment)
        let luminance = 0.2126 * resolved.red + 0.7152 * resolved.green + 0.0722 * resolved.blue
        return luminance < 0.5 ? .white : .black
    }
}
