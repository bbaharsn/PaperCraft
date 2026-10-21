//
//  FontPickerList.swift
//  PaperCraft
//

import SwiftUI

/// Yazı tiplerinin listesi; her ad kendi yazı tipiyle yazılır, seçilen işaretlenir.
/// Özellikler sayfasından içeri itilerek (push) açılır, seçince geri döner.
struct FontPickerList: View {
    @Binding var fontName: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(FontFamilies.all, id: \.self) { name in
            Button {
                fontName = name
                dismiss()
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
        .navigationTitle("Yazı Tipi")
    }
}

#Preview {
    @Previewable @State var fontName = "Georgia"
    NavigationStack {
        FontPickerList(fontName: $fontName)
    }
}
