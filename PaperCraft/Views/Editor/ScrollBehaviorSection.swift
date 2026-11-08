//
//  ScrollBehaviorSection.swift
//  PaperCraft
//

import SwiftUI

/// Üst bar ve alt menünün "Kaydırınca" seçeneği: sayfa kayarken yerinde mi dursun, içerikle mi kaysın.
struct ScrollBehaviorSection: View {
    let viewModel: EditorViewModel

    var body: some View {
        Section {
            OptionPicker(selection: viewModel.binding(\.scrollBehavior, default: .fixed), title: \.title)
        } header: {
            Text("Kaydırınca")
        } footer: {
            Text("Sabit: sayfa kayarken yerinde durur, içerik altından geçer. Sayfa uzun değilse fark etmez.")
        }
    }
}
