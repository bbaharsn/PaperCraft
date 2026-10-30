//
//  ElementView.swift
//  PaperCraft
//

import SwiftUI

/// Tek bir `CanvasElement`'i türüne göre gerçek SwiftUI bileşeni olarak çizer.
/// Önizlemede `interactive` verilir: switch açılır, slider kayar, metin yazılır, sekme seçilir.
struct ElementView: View {
    let element: CanvasElement
    /// Önizlemede elemanın değiştirilebilir kopyası; canvas'ta `nil` (sadece görüntü).
    var interactive: Binding<ElementProperties>? = nil

    var body: some View {
        let properties = element.properties

        switch element.type {
        case .text:
            TextElementView(properties: properties)

        case .button:
            if interactive != nil {
                // Henüz bir yere gitmez; basınca hafifçe kararır
                Button {} label: { ButtonElementView(properties: properties) }
                    .buttonStyle(PressDimmingButtonStyle())
            } else {
                ButtonElementView(properties: properties)
            }

        case .textField:
            TextFieldElementView(properties: properties, interactive: interactive)

        case .image:
            ImageElementView(properties: properties)

        case .switch:
            SwitchElementView(properties: properties, interactive: interactive)

        case .slider:
            SliderElementView(properties: properties, interactive: interactive)

        case .navigationBar:
            NavigationBarElementView(properties: properties)

        case .tabBar:
            TabBarElementView(properties: properties, interactive: interactive)

        case .unknown:
            Image(systemName: "questionmark.square.dashed")
        }
    }
}

#Preview {
    let catalog = try! ComponentCatalog.load()
    VStack(spacing: 16) {
        ForEach(MockScreens.login(using: catalog).elements) { element in
            ElementView(element: element)
        }
    }
    .padding()
}
