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
            Text(properties.text ?? "")
                .font(properties.textStyle == "largeTitle" ? .largeTitle.bold() : .body)

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
            Slider(value: .constant(properties.value ?? 0.5))

        case .navigationBar:
            Text(properties.text ?? "")
                .font(.headline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.bar)

        case .tabBar:
            HStack {
                ForEach(properties.items ?? [], id: \.text) { item in
                    VStack {
                        Image(systemName: item.symbolName)
                        Text(item.text).font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxHeight: .infinity)
            .background(.bar)

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
