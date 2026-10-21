//
//  FontPickerRow.swift
//  PaperCraft
//

import SwiftUI

/// Seçili yazı tipinin adını kendi tipiyle gösteren satır; dokununca `FontPickerList` açılır.
/// Metin ve üst bar sayfaları ortak kullanır.
struct FontPickerRow: View {
    @Binding var fontName: String

    var body: some View {
        NavigationLink {
            FontPickerList(fontName: $fontName)
        } label: {
            Text(FontFamilies.title(of: fontName))
                .font(TextElementView.font(named: fontName, style: .body))
        }
    }
}

#Preview {
    @Previewable @State var fontName = "Georgia"
    NavigationStack {
        Form { FontPickerRow(fontName: $fontName) }
    }
}
