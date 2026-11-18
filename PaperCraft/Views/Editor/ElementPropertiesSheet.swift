//
//  ElementPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Alttan açılan "Özellikler" sayfasının çerçevesi: başlık, "Bitti" ve
/// seçili elemanın türüne göre doğru içerik.
struct ElementPropertiesSheet: View {
    let viewModel: EditorViewModel
    /// Verilirse "Bitti" bunu çağırır (iPad'deki sabit panel); verilmezse sayfayı kapatır.
    var onDone: (() -> Void)? = nil

    /// "Bitti" sadece sayfayı kapatır; eleman seçili kalır.
    @Environment(\.dismiss) private var dismiss

    /// Özellikler sayfası olan türler. Yeni bir tür eklenince buraya ve `content`'e eklenir.
    static func hasSheet(for type: ElementType) -> Bool {
        type == .text || type == .button || type == .textField || type == .switch || type == .slider
            || type == .navigationBar || type == .tabBar || type == .image || type == .symbol || type == .box
    }

    private var type: ElementType? {
        viewModel.selectedElement?.type
    }

    var body: some View {
        if let onDone {
            // iPad paneli editörün kendi gezinme yığınının içinde durur; içine ikinci bir
            // NavigationStack koymak editörü kapatıyor. Başlık ve "Bitti" elle çizilir.
            PanelHeaderStack(title: title, onDone: onDone) {
                form
            }
            // Başka eleman seçilince açık alt sayfa (font listesi, sekme) kapanır, panel baştan açılır
            .id(viewModel.selectedElement?.id)
        } else {
            NavigationStack {
                form
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
    }

    private var form: some View {
        Form {
            content
        }
        .scrollContentBackground(.hidden)
        .background(Theme.panel)
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
        case .tabBar: TabBarPropertiesSheet(viewModel: viewModel)
        case .image: ImagePropertiesSheet(viewModel: viewModel)
        case .symbol: SymbolPropertiesSheet(viewModel: viewModel)
        case .box: BoxPropertiesSheet(viewModel: viewModel)
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
        case .tabBar: "Alt Menü"
        case .image: "Görsel"
        case .symbol: "Sembol"
        case .box: "Kutu"
        default: "Özellikler"
        }
    }
}
