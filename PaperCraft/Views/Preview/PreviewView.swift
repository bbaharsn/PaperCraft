//
//  PreviewView.swift
//  PaperCraft
//

import SwiftUI

/// "Dene" ile açılan önizleme: canvas'taki kart büyüyerek tüm ekranı kaplar ve gerçek bir uygulama gibi dokunulur.
/// Ekranın bir kopyasıyla çalışır; switch'i açmak ya da yazı yazmak tasarımı değiştirmez.
/// Sağ üstteki butonla ya da aşağı kaydırarak kapanır; kart canvas'taki yerine geri küçülür.
struct PreviewView: View {
    /// Canvas kartının ekrandaki yeri; önizleme buradan büyür, buraya küçülür.
    let cardFrame: CGRect
    /// Kapanma animasyonu bitince çağrılır.
    let onClose: () -> Void

    @State private var screen: PrototypeScreen
    @State private var isExpanded = false
    /// Aşağı kaydırırken ekranın ne kadar indiği (point).
    @State private var dismissOffset: CGFloat = 0

    /// Bu kadar aşağı kaydırılınca önizleme kapanır.
    private static let dismissDistance: CGFloat = 140

    init(screen: PrototypeScreen, cardFrame: CGRect, onClose: @escaping () -> Void) {
        _screen = State(initialValue: screen)
        self.cardFrame = cardFrame
        self.onClose = onClose
    }

    var body: some View {
        GeometryReader { geometry in
            let insets = geometry.safeAreaInsets
            // Güvenli alan dahil tüm ekran
            let screenSize = CGSize(width: geometry.size.width + insets.leading + insets.trailing,
                                    height: geometry.size.height + insets.top + insets.bottom)
            let global = geometry.frame(in: .global)
            let card = cardFrame.isEmpty
                ? CGRect(origin: .zero, size: screenSize)
                : cardFrame.offsetBy(dx: insets.leading - global.minX, dy: insets.top - global.minY)

            let stageWidth = PreviewLayout.stageWidth(for: screenSize)
            let cardScale = card.width / stageWidth
            // Kapalıyken kart birebir canvas'taki gibidir; açılırken durum çubuğu payı da animasyonla gelir
            let layout = PreviewLayout(
                stageSize: CGSize(width: stageWidth,
                                  height: isExpanded ? screenSize.height : card.height / cardScale),
                topInset: isExpanded ? insets.top : 0
            )

            ZStack(alignment: .topTrailing) {
                // Tasarım telefon oranında kaldığı için geniş ekranlarda yanları doldurur
                Theme.background
                    .opacity(isExpanded && dismissOffset == 0 ? 1 : 0)

                stage(layout)
                    .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 0 : Theme.cornerRadius / cardScale))
                    .scaleEffect(isExpanded ? 1 : cardScale)
                    .position(x: isExpanded ? screenSize.width / 2 : card.midX,
                              y: (isExpanded ? screenSize.height / 2 : card.midY) + dismissOffset)

                closeButton
                    .padding(.top, insets.top + 4)
                    .padding(.trailing, insets.trailing + 12)
                    .opacity(isExpanded ? 1 : 0)
            }
            .frame(width: screenSize.width, height: screenSize.height)
            .ignoresSafeArea(.container)
        }
        // Klavye açılınca da tasarım yerinden oynamaz
        .ignoresSafeArea(.keyboard)
        .simultaneousGesture(dismissGesture)
        .onAppear {
            withAnimation(.snappy(duration: 0.4)) { isExpanded = true }
        }
    }

    /// Tasarım: durum çubuğu payı ve elemanlar. Gerçek boyutta çizip ekrana sığdırılır; canvas ile aynı oranlar.
    private func stage(_ layout: PreviewLayout) -> some View {
        let size = CanvasView.referenceSize
        return ZStack(alignment: .topLeading) {
            Theme.paper
                // Boş yere dokununca klavye kapansın
                .onTapGesture { hideKeyboard() }

            // Üst bar, gerçek uygulamadaki gibi durum çubuğunun arkasına da uzanır
            statusBarFill
                .frame(height: layout.topInset)

            elementsLayer(layout)
                .frame(width: size.width, height: layout.designHeight)
                .scaleEffect(layout.scale, anchor: .topLeading)
                .offset(y: layout.topInset)
        }
        .frame(width: layout.stageSize.width, height: layout.stageSize.height, alignment: .topLeading)
    }

    /// Ekranda üst bar varsa durum çubuğunun arkası onun rengini alır.
    private var statusBarFill: Color {
        let navigationBar = screen.elements.first { $0.type == .navigationBar }
        return navigationBar.map { NavigationBarElementView(properties: $0.properties).backgroundColor } ?? .clear
    }

    /// Tüm elemanlar, gerçek iPhone point'leriyle yerleştirilmiş ve dokunulabilir halde.
    private func elementsLayer(_ layout: PreviewLayout) -> some View {
        let size = CanvasView.referenceSize
        return ZStack {
            ForEach(Array(screen.elements.enumerated()), id: \.element.id) { index, element in
                let frame = element.frame
                ElementView(element: element, interactive: binding(for: element))
                    .frame(width: frame.width * size.width, height: frame.height * size.height)
                    .rotationEffect(.degrees(element.properties.rotation ?? 0))
                    .position(layout.center(of: frame))
                    .zIndex(Double(index))
            }
        }
    }

    /// Elemanın özelliklerine önizleme kopyası üzerinden bağlantı.
    private func binding(for element: CanvasElement) -> Binding<ElementProperties> {
        Binding(
            get: { screen.elements.first { $0.id == element.id }?.properties ?? element.properties },
            set: { newValue in screen.updateProperties(of: element.id) { $0 = newValue } }
        )
    }

    private var closeButton: some View {
        Button { close() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.ink.opacity(0.7))
                .frame(width: 30, height: 30)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .opacity(0.8)
        .accessibilityLabel("Önizlemeyi kapat")
        .keyboardShortcut(.cancelAction)
    }

    /// Aşağı kaydırınca ekran parmakla iner; yeterince inerse kapanır, inmezse geri döner.
    /// Sadece belirgin dikey kaydırmalar sayılır; slider'ı yana kaydırmak önizlemeyi oynatmaz.
    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let isVertical = value.translation.height > abs(value.translation.width) * 2
                dismissOffset = isVertical ? max(0, value.translation.height) : 0
            }
            .onEnded { _ in
                if dismissOffset > Self.dismissDistance {
                    close()
                } else {
                    withAnimation(.snappy) { dismissOffset = 0 }
                }
            }
    }

    /// Kart canvas'taki yerine küçülür, animasyon bitince önizleme kalkar.
    private func close() {
        hideKeyboard()
        withAnimation(.snappy(duration: 0.35)) {
            isExpanded = false
            dismissOffset = 0
        } completion: {
            onClose()
        }
    }

    private func hideKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

#Preview {
    PreviewView(screen: MockScreens.login(using: try! ComponentCatalog.load()), cardFrame: .zero, onClose: {})
}
