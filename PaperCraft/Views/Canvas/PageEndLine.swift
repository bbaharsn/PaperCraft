//
//  PageEndLine.swift
//  PaperCraft
//

import SwiftUI

/// Editörde sayfanın gerçek bittiği yeri gösteren kesik çizgi. Dene'de ve sayfa kartlarında sayfa burada biter;
/// altındaki boşluk sadece editörde, yeni eleman koymak için vardır.
struct PageEndLine: View {
    /// Tuvalin ölçeği; çizgi ve yazı ekranda hep aynı kalınlıkta görünsün diye.
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .trailing) {
            Rectangle()
                .stroke(Theme.ink.opacity(0.45), style: StrokeStyle(lineWidth: 1 / scale, dash: [6 / scale, 4 / scale]))
                .frame(height: 1 / scale)
            Text("Sayfa sonu")
                .font(.system(size: 11 / scale, weight: .semibold))
                .foregroundStyle(Theme.paper)
                .padding(.horizontal, 6 / scale)
                .padding(.vertical, 2 / scale)
                .background(Theme.ink.opacity(0.6), in: Capsule())
                .padding(.trailing, 8 / scale)
        }
        .allowsHitTesting(false)
    }
}
