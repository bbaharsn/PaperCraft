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

    /// Projenin sayfalarının kopyası.
    @State private var screens: [PrototypeScreen]
    /// Gezilen sayfalar; sondaki açık olan. "Geri dön" bir öncekine iner.
    @State private var history: [UUID]
    /// Sayfa geçişinin geldiği yön.
    @State private var pushEdge: Edge = .trailing
    @State private var isExpanded = false
    /// Aşağı kaydırırken ekranın ne kadar indiği (point).
    @State private var dismissOffset: CGFloat = 0
    /// Açık klavyenin yüksekliği (point); kapalıyken 0.
    @State private var keyboardHeight: CGFloat = 0
    /// Yazı yazılan metin kutusu.
    @FocusState private var focusedElementID: UUID?
    /// Uzun sayfa en üstte mi? Aşağı çekip kapatma sadece en üstteyken çalışır.
    @State private var isScrolledToTop = true

    /// Uzun sayfanın kaydırma alanının adı; en üstte olup olmadığı buna göre ölçülür.
    private static let scrollSpace = "previewScroll"

    /// Bu kadar aşağı kaydırılınca önizleme kapanır.
    private static let dismissDistance: CGFloat = 140

    init(screens: [PrototypeScreen], startID: UUID, cardFrame: CGRect, onClose: @escaping () -> Void) {
        _screens = State(initialValue: screens)
        _history = State(initialValue: [startID])
        self.cardFrame = cardFrame
        self.onClose = onClose
    }

    /// Açık olan sayfa.
    private var screen: PrototypeScreen {
        screens.first { $0.id == history.last } ?? screens.first ?? PrototypeScreen(name: "")
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
                    .padding(.top, closeButtonTop(layout))
                    .padding(.trailing, insets.trailing + 12)
                    .opacity(isExpanded ? 1 : 0)
            }
            .frame(width: screenSize.width, height: screenSize.height)
            .ignoresSafeArea(.container)
        }
        // Klavye açılınca da tasarım yerinden oynamaz
        .ignoresSafeArea(.keyboard)
        .simultaneousGesture(dismissGesture)
        #if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            keyboardHeight = frame?.height ?? 0
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        #endif
        .onAppear {
            withAnimation(.snappy(duration: 0.4)) { isExpanded = true }
        }
    }

    /// Tasarım: durum çubuğu payı ve elemanlar. Gerçek boyutta çizip ekrana sığdırılır; canvas ile aynı oranlar.
    private func stage(_ layout: PreviewLayout) -> some View {
        let size = CanvasView.referenceSize
        let focusedFrame = screen.elements.first { $0.id == focusedElementID }?.frame
        let lift = focusedFrame.map { layout.keyboardLift(for: $0, keyboardHeight: keyboardHeight) } ?? 0
        return ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                if screen.contentHeight > 1 {
                    scrollingPage(layout)
                } else {
                    ScreenBackgroundView(background: screen.background)
                        // Boş yere dokununca klavye kapansın
                        .onTapGesture { hideKeyboard() }

                    elementsLayer(layout, screen.elements, scrolling: false)
                        .frame(width: size.width, height: layout.designHeight)
                        .scaleEffect(layout.scale, anchor: .topLeading)
                        // Klavye yazılan kutuyu kapatacaksa tasarım yukarı kayar
                        .offset(y: layout.topInset - lift)
                        .animation(.snappy(duration: 0.25), value: lift)
                }

                // Üst bar, gerçek uygulamadaki gibi durum çubuğunun arkasına da uzanır;
                // tasarım yukarı kayınca elemanlar bunun altından geçer
                statusBarFill(layout)
            }
            .pageBackdrop(screen.background, size: layout.stageSize)
            // Sayfa değişince yenisi yandan kayarak gelir
            .id(screen.id)
            .transition(.push(from: pushEdge))
        }
        .frame(width: layout.stageSize.width, height: layout.stageSize.height, alignment: .topLeading)
    }

    /// Uzun sayfa: içerik canvas'taki gibi birebir konumlarda aşağı kayar; sabit üst bar ve alt menü
    /// kaymaz, durum çubuğunun altında ve en altta durur. Uzun sayfada klavye tasarımı kaldırmaz.
    private func scrollingPage(_ layout: PreviewLayout) -> some View {
        let size = CanvasView.referenceSize
        let contentHeight = layout.scrollingContentHeight(for: screen)
        let pinned = screen.elements.filter(\.isPinned)
        let scrolling = screen.elements.filter { !$0.isPinned }

        return ZStack(alignment: .topLeading) {
            ScrollView(.vertical) {
                ZStack(alignment: .topLeading) {
                    ScreenBackgroundView(background: screen.background)
                        .onTapGesture { hideKeyboard() }
                    elementsLayer(layout, scrolling, scrolling: true)
                }
                .frame(width: size.width, height: contentHeight)
                .pageBackdrop(screen.background, size: CGSize(width: size.width, height: contentHeight))
                .scaleEffect(layout.scale, anchor: .topLeading)
                .frame(width: layout.stageSize.width, height: contentHeight * layout.scale, alignment: .topLeading)
                .onGeometryChange(for: Bool.self) { proxy in
                    proxy.frame(in: .named(Self.scrollSpace)).minY >= layout.topInset - 1
                } action: { isScrolledToTop = $0 }
            }
            .coordinateSpace(name: Self.scrollSpace)
            // İlk ekranın üstü durum çubuğunun altında başlar; kaydırınca içerik onun arkasından geçer
            .contentMargins(.top, layout.topInset, for: .scrollContent)
            .scrollIndicators(.hidden)
            // Yukarı-aşağı esneme sırasında arkası boş görünmesin
            .background(ScreenBackgroundView(background: screen.background))

            elementsLayer(layout, pinned, scrolling: false)
                .frame(width: size.width, height: layout.designHeight)
                .scaleEffect(layout.scale, anchor: .topLeading)
                .offset(y: layout.topInset)
        }
    }

    /// Ekranda üst bar varsa durum çubuğunun arkası onun rengini alır.
    /// Yoksa arka planın aynı şeridi çizilir; geçiş kesintisiz devam eder.
    @ViewBuilder
    private func statusBarFill(_ layout: PreviewLayout) -> some View {
        if let navigationBar = screen.elements.first(where: { $0.type == .navigationBar }) {
            NavigationBarElementView(properties: navigationBar.properties).backgroundColor
                .frame(height: layout.topInset)
        } else {
            ScreenBackgroundView(background: screen.background)
                .mask(alignment: .top) {
                    Rectangle().frame(height: layout.topInset)
                }
                .allowsHitTesting(false)
        }
    }

    /// Verilen elemanlar, gerçek iPhone point'leriyle yerleştirilmiş ve dokunulabilir halde.
    /// `scrolling` true ise kayan sayfanın birebir konumları, değilse durum çubuğunun altına yayılan konumlar.
    private func elementsLayer(_ layout: PreviewLayout, _ elements: [CanvasElement], scrolling: Bool) -> some View {
        let size = CanvasView.referenceSize
        return ZStack {
            ForEach(Array(elements.enumerated()), id: \.element.id) { index, element in
                let frame = element.frame
                ElementView(element: element, interactive: binding(for: element), onAction: perform)
                    .focused($focusedElementID, equals: element.id)
                    .frame(width: frame.width * size.width, height: frame.height * size.height)
                    .rotationEffect(.degrees(element.properties.rotation ?? 0))
                    .position(scrolling ? layout.scrollingCenter(of: frame) : layout.center(of: frame))
                    .zIndex(Double(index))
            }
        }
    }

    /// Elemanın özelliklerine önizleme kopyası üzerinden bağlantı.
    private func binding(for element: CanvasElement) -> Binding<ElementProperties> {
        Binding(
            get: { screen.elements.first { $0.id == element.id }?.properties ?? element.properties },
            set: { newValue in
                guard let index = screens.firstIndex(where: { $0.id == screen.id }) else { return }
                screens[index].updateProperties(of: element.id) { $0 = newValue }
            }
        )
    }

    /// Kapat butonu üst barın sağındaki butonu kapatmasın diye o varsa barın altına iner.
    private func closeButtonTop(_ layout: PreviewLayout) -> CGFloat {
        let bar = screen.elements.first { $0.type == .navigationBar }
        guard let bar, (bar.properties.trailingItem ?? .none) != .none else { return layout.topInset + 4 }
        return layout.topInset + bar.frame.height * CanvasView.referenceSize.height * layout.scale + 8
    }

    /// Dokunulan elemanın bağlantısını çalıştırır. Sayfa silinmişse ya da geri gidecek sayfa yoksa bir şey olmaz.
    private func perform(_ action: ElementAction) {
        switch action {
        case .none:
            break
        case .back:
            // Dene ortadaki bir sayfadan açıldıysa geri, projenin ilk sayfasına döner
            if history.count == 1, let first = screens.first?.id, first != history[0] {
                history.insert(first, at: 0)
            }
            guard history.count > 1 else { return }
            hideKeyboard()
            pushEdge = .leading
            withAnimation(.snappy(duration: 0.3)) { _ = history.removeLast() }
        case .goTo(let screenID):
            guard screens.contains(where: { $0.id == screenID }) else { return }
            hideKeyboard()
            pushEdge = .trailing
            withAnimation(.snappy(duration: 0.3)) { history.append(screenID) }
        }
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
                // Uzun sayfa aşağıdayken aşağı çekmek sayfayı kaydırır, önizlemeyi kapatmaz
                guard isScrolledToTop || dismissOffset > 0 else { return }
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
    let screen = MockScreens.login(using: try! ComponentCatalog.load())
    PreviewView(screens: [screen], startID: screen.id, cardFrame: .zero, onClose: {})
}
