//
//  BackgroundPropertiesSheet.swift
//  PaperCraft
//

import SwiftUI

/// Sayfanın arka planını değiştiren alttan açılan sayfa: düz renk ya da iki veya üç renkli geçiş.
struct BackgroundPropertiesSheet: View {
    let viewModel: EditorViewModel
    /// Verilirse "Bitti" bunu çağırır (iPad'deki sabit panel); verilmezse sayfayı kapatır.
    var onDone: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    /// Hazır renkler: kağıt, beyaz, siyah ve yumuşak tonlar.
    private let presets = [ScreenBackground.defaultColor, "#FFFFFF", "#111111", "#F4C6A8",
                           "#FFD6E0", "#BDE0FE", "#C7F0D8", "#AC5135", "#007AFF"]

    private var kind: BackgroundKind {
        viewModel.backgroundBinding(\.kind).wrappedValue
    }

    var body: some View {
        if let onDone {
            // iPad paneli: editörün gezinme yığınının içinde, kendi NavigationStack'i olmadan.
            PanelHeaderStack(title: "Arka Plan", onDone: onDone) {
                form
            }
        } else {
            NavigationStack {
                form
                    .navigationTitle("Arka Plan")
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
                Section("Tür") {
                    OptionPicker(selection: viewModel.backgroundBinding(\.kind), title: \.title)
                }

                Section(kind == .solid ? "Renk" : "Başlangıç rengi") {
                    ColorSwatchRow(hex: viewModel.backgroundBinding(\.color), presets: presets)
                }

                if kind == .threeColors {
                    Section("Orta renk") {
                        ColorSwatchRow(hex: viewModel.backgroundBinding(\.middleColor), presets: presets)
                    }
                }

                if kind != .solid {
                    Section("Bitiş rengi") {
                        ColorSwatchRow(hex: viewModel.backgroundBinding(\.endColor), presets: presets)
                    }

                    Section("Yön") {
                        OptionPicker(selection: viewModel.backgroundBinding(\.direction), title: \.title)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.panel)
    }
}

#Preview {
    BackgroundPropertiesSheet(viewModel: EditorViewModel(catalog: try! ComponentCatalog.load(),
                                                         screen: PrototypeScreen(name: "Önizleme")))
}
