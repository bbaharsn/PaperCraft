//
//  ElementPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Alttan açılan "Özellikler" sayfasının çerçevesi: başlık, "Bitti" ve
/// seçili elemanın türüne göre doğru içerik.
struct ElementPropertiesSheet: View {
    let viewModel: EditorViewModel

    /// "Bitti" sadece sayfayı kapatır; eleman seçili kalır.
    @Environment(\.dismiss) private var dismiss

    /// Özellikler sayfası olan türler. Yeni bir tür eklenince buraya ve `content`'e eklenir.
    static func hasSheet(for type: ElementType) -> Bool {
        type == .text || type == .button || type == .textField || type == .switch || type == .slider
            || type == .navigationBar
    }

    private var type: ElementType? {
        viewModel.selectedElement?.type
    }

    var body: some View {
        NavigationStack {
            Form {
                content
            }
            .scrollContentBackground(.hidden)
            .background(Theme.panel)
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bitti") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch type {
        case .text: TextPropertiesSheet(viewModel: viewModel)
        case .button: ButtonPropertiesSheet(viewModel: viewModel)
        case .textField: TextFieldPropertiesSheet(viewModel: viewModel)
        case .switch: SwitchPropertiesSheet(viewModel: viewModel)
        case .slider: SliderPropertiesSheet(viewModel: viewModel)
        case .navigationBar: NavigationBarPropertiesSheet(viewModel: viewModel)
        default: EmptyView()
        }
    }

    private var title: String {
        switch type {
        case .text: "Metin"
        case .button: "Buton"
        case .textField: "Metin Kutusu"
        case .switch: "Anahtar"
        case .slider: "Kaydırıcı"
        case .navigationBar: "Üst Bar"
        default: "Özellikler"
        }
    }
}
