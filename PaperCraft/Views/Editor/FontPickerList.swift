//
//  FontPickerList.swift
//  PaperCraft
//

import SwiftUI

/// Yazı tiplerinin listesi; her ad kendi yazı tipiyle yazılır, seçilen işaretlenir.
/// Özellikler sayfasından içeri itilerek (push) açılır; seçince açık kalır, "Geri" ile dönülür.
struct FontPickerList: View {
    @Binding var fontName: String

    var body: some View {
        List(FontFamilies.all, id: \.self) { name in
            // Seçince liste açık kalır; kullanıcı fontları canvas'ta deneyip "Geri" ile döner
            Button {
                fontName = name
            } label: {
                HStack {
                    Text(FontFamilies.title(of: name))
                        .font(TextElementView.font(named: name, style: .title))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if name == fontName {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Theme.ink)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.panel)
        // Başlık `PanelLink`'ten gelir
    }
}

#Preview {
    @Previewable @State var fontName = "Georgia"
    NavigationStack {
        FontPickerList(fontName: $fontName)
            .navigationTitle("Yazı Tipi")
    }
}
