//
//  ElementView.swift
//  PaperCraft
//

import SwiftUI

/// Tek bir `CanvasElement`'i türüne göre gerçek SwiftUI bileşeni olarak çizer.
struct ElementView: View {
    let element: CanvasElement

    var body: some View {
        let properties = element.properties

        switch element.type {
        case .text:
            TextElementView(properties: properties)

        case .button:
            ButtonElementView(properties: properties)

        case .textField:
            TextFieldElementView(properties: properties)

        case .image:
            Image(systemName: properties.symbolName ?? "photo")
                .resizable()
                .scaledToFit()

        case .switch:
            SwitchElementView(properties: properties)

        case .slider:
            SliderElementView(properties: properties)

        case .navigationBar:
            NavigationBarElementView(properties: properties)

        case .tabBar:
            TabBarElementView(properties: properties)

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
