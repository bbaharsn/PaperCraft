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
    /// Önizlemede butona basınca çağrılır.
    var onAction: (ElementAction) -> Void = { _ in }

    var body: some View {
        let properties = element.properties

        switch element.type {
        case .text:
            TextElementView(properties: properties)

        case .button:
            if interactive != nil {
                // Basınca hafifçe kararır; bağlantısı varsa o sayfaya gider
                Button { onAction(properties.action ?? .none) } label: { ButtonElementView(properties: properties) }
                    .buttonStyle(PressDimmingButtonStyle())
            } else {
                ButtonElementView(properties: properties)
            }

        case .textField:
            TextFieldElementView(properties: properties, interactive: interactive)

        case .image:
            tappable { ImageElementView(properties: properties) }

        case .symbol:
            tappable { SymbolElementView(properties: properties) }

        case .switch:
            SwitchElementView(properties: properties, interactive: interactive)

        case .slider:
            SliderElementView(properties: properties, interactive: interactive)

        case .navigationBar:
            NavigationBarElementView(properties: properties,
                                     onBack: interactive != nil ? { onAction(.back) } : nil,
                                     onTrailing: interactive != nil ? { onAction(properties.action ?? .none) } : nil)

        case .tabBar:
            TabBarElementView(properties: properties, interactive: interactive, onAction: onAction)

        case .unknown:
            Image(systemName: "questionmark.square.dashed")
        }
    }
}

private extension ElementView {
    /// Bağlantısı olan görsel ve semboller önizlemede buton gibi davranır.
    @ViewBuilder
    func tappable<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let action = element.properties.action ?? .none
        if interactive != nil, action != .none {
            Button { onAction(action) } label: { content().contentShape(Rectangle()) }
                .buttonStyle(PressDimmingButtonStyle())
        } else {
            content()
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
