//
//  BoolPicker.swift
//  PaperCraft
//

import SwiftUI

/// Açık/kapalı bir özelliği anahtar (switch) yerine iki bölmeli seçici olarak gösterir.
/// Kullanım: `BoolPicker(isOn: $showsDivider)` ya da `BoolPicker(isOn: $isItalic, off: "Düz", on: "İtalik")`
struct BoolPicker: View {
    @Binding var isOn: Bool
    var off = "Yok"
    var on = "Var"

    var body: some View {
        Picker("", selection: $isOn) {
            Text(off).tag(false)
            Text(on).tag(true)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}

#Preview {
    @Previewable @State var isOn = true
    BoolPicker(isOn: $isOn)
        .padding()
}
