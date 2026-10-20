//
//  OptionPicker.swift
//  PaperCraft
//

import SwiftUI

/// Bir enum'un tüm seçeneklerini yan yana bölmeli (segmented) seçici olarak gösterir.
/// Kullanım: `OptionPicker(selection: $shape, title: \.title)`
struct OptionPicker<Option: CaseIterable & Hashable>: View where Option.AllCases: RandomAccessCollection {
    @Binding var selection: Option
    let title: KeyPath<Option, String>

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(Array(Option.allCases), id: \.self) { option in
                Text(option[keyPath: title]).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}
