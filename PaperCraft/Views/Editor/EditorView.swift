//
//  EditorView.swift
//  PaperCraft
//
//  Created by Bahar Şen on 13.10.2026.
//

import SwiftData
import SwiftUI

/// Bir sayfanın editörü: üst bar, canvas, katalog ve Özellikler sayfası.
/// Her değişiklik anında projeye yazılır; "Kaydet" yok.
struct EditorView: View {
    let project: Project
    let record: ScreenRecord
    @State private var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    /// Alt katalog açık mı? Sadece bu ekranı ilgilendiren bir görünüm durumu.
    @State private var isCatalogOpen = false
    /// Katalogdan sembol eklenirken önce sembol seçilir; eleman seçimden sonra eklenir.
    @State private var isPickingSymbol = false
    /// Sayfanın "Arka Plan" ayarları açık mı?
    @State private var isEditingBackground = false

    /// Kullanıcı Özellikler sayfasını istedi mi (çift dokunuş)?
    /// Tek dokunuş sadece seçer; sayfa açılmadan taşınır ve boyutlandırılır.
    @State private var wantsProperties = false

    /// "Dene" ile açılan tam ekran önizleme.
    @State private var isPreviewing = false
    /// Canvas kartının ekrandaki yeri; önizleme buradan büyür.
    @State private var canvasCardFrame: CGRect = .zero
    /// Ekran noktası → sayfa noktası eşlemesi; katalogdan bırakılan eleman buna göre yerleşir.
    @State private var canvasMapping: CanvasMapping?
    /// Katalogdan sürüklenen eleman ve parmağın ekrandaki yeri.
    @State private var catalogDrag: (element: CanvasElement, location: CGPoint)?
    /// Sembol canvas'a bırakıldıysa, sembol seçilince eleman bu noktaya (normalize) yerleşir.
    @State private var symbolDropPoint: CGPoint?

    /// Özellikler sayfasının yarım açıkken yüksekliği (point).
    private static let propertiesSheetHeight: CGFloat = 340
    /// Açık sayfanın boyu (yarım ya da tam). `-largeSheet` ile tam boy başlar.
    @State private var sheetDetent: PresentationDetent =
        DebugLaunchOptions.opensLargeSheet ? .large : .height(EditorView.propertiesSheetHeight)

    init(project: Project, record: ScreenRecord) {
        self.project = project
        self.record = record
        let screen = record.screen ?? PrototypeScreen(name: "Sayfa")
        let editor = Self.makeEditor(screen: screen)
        editor.linkTargets = project.previewScreens
            .filter { $0.id != screen.id }
            .map { ScreenLink(id: $0.id, name: $0.name) }
        _viewModel = State(initialValue: editor)
    }

    /// Sayfa, istendiğinde ve seçili elemanın bir Özellikler sayfası olduğunda açıktır.
    /// Aşağı kaydırılıp ya da "Bitti" ile kapatılırsa seçim kalır, sadece sayfa kapanır.
    private var isShowingProperties: Binding<Bool> {
        Binding(
            get: {
                guard wantsProperties, let type = viewModel.selectedElement?.type else { return false }
                return ElementPropertiesSheet.hasSheet(for: type)
            },
            set: { wantsProperties = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorTopBar(
                pageName: viewModel.screen.name,
                onBack: { dismiss() },
                canUndo: viewModel.canUndo,
                canRedo: viewModel.canRedo,
                onUndo: { viewModel.undo() },
                onRedo: { viewModel.redo() },
                onToggleCatalog: {
                    withAnimation(.snappy) {
                        isCatalogOpen.toggle()
                    }
                },
                onPreview: {
                    wantsProperties = false
                    isPreviewing = true
                }
            )
            // Canvas yukarı kaydığında üst barın altından geçsin, üstüne binmesin
            .zIndex(1)
            CanvasView(viewModel: viewModel,
                       onDoubleTap: { wantsProperties = true },
                       onBackgroundDoubleTap: { isEditingBackground = true },
                       // Sayfa açıkken canvas küçülmez; seçili eleman sayfanın altında kalırsa yukarı kayar.
                       bottomInset: isShowingProperties.wrappedValue ? Self.propertiesSheetHeight : 0,
                       onCardFrameChange: { canvasCardFrame = $0 },
                       onMappingChange: { canvasMapping = $0 })
                .padding()
                // overlay: canvas'ın boyutunu değiştirmeden üstüne yüzer
                .overlay(alignment: .bottom) {
                    if viewModel.selectedElementID != nil {
                        SelectionToolbar(
                            onDuplicate: viewModel.canDuplicateSelected ? { viewModel.duplicateSelectedElement() } : nil,
                            onDelete: { viewModel.deleteSelectedElement() }
                        )
                        .padding(.bottom, 32)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.snappy, value: viewModel.selectedElementID)
                .animation(.snappy, value: wantsProperties)
                .sheet(isPresented: $isEditingBackground, onDismiss: resetSheetDetent) {
                    BackgroundPropertiesSheet(viewModel: viewModel)
                        .presentationDetents([.height(Self.propertiesSheetHeight), .large], selection: $sheetDetent)
                        .presentationDragIndicator(.visible)
                        // Sayfa açıkken değişiklik canvas'ta görünsün, üstü kararmasın.
                        .presentationBackgroundInteraction(.enabled(upThrough: .height(Self.propertiesSheetHeight)))
                }

            if isCatalogOpen {
                CatalogPanel(
                    catalog: viewModel.catalog,
                    onSelect: { type in add(type, at: nil) },
                    onBackground: {
                        wantsProperties = false
                        isEditingBackground = true
                    },
                    onDragChanged: { type, location in
                        if let drag = catalogDrag {
                            catalogDrag = (drag.element, location)
                        } else if let element = viewModel.catalog.makeElement(of: type) {
                            wantsProperties = false
                            catalogDrag = (element, location)
                        }
                    },
                    onDragEnded: { type, location in
                        catalogDrag = nil
                        // Canvas'ın dışına bırakılırsa hiçbir şey eklenmez.
                        guard let point = canvasMapping?.pagePoint(forGlobal: location) else { return }
                        add(type, at: point)
                    }
                )
                    .transition(.move(edge: .bottom))
                    .sheet(isPresented: $isPickingSymbol, onDismiss: { symbolDropPoint = nil }) {
                        SymbolCatalogSheet(symbols: viewModel.symbolCatalog.symbols) { name in
                            viewModel.addSymbol(named: name, centeredAt: symbolDropPoint)
                        }
                    }
            }
        }
        .background(Theme.background)
        // Üst barı kendimiz çiziyoruz; sistemin gezinme çubuğu görünmesin.
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        // Seçim tamamen kalkınca istek de sıfırlanır; yoksa sonraki tek dokunuş sayfayı açardı.
        .onChange(of: viewModel.selectedElementID) { _, newID in
            if newID == nil { wantsProperties = false } else { isEditingBackground = false }
        }
        // Otomatik kaydetme: ekran her değiştiğinde projeye yazılır.
        .onChange(of: viewModel.screen) { _, newScreen in
            project.save(newScreen, to: record)
        }
        .task { await openPropertiesForDebugIfNeeded() }
        // SwiftData kendisi de ara ara kaydeder; editörden çıkarken beklemeden diske yazalım.
        .onDisappear {
            try? context.save()
        }
        .sheet(isPresented: isShowingProperties, onDismiss: resetSheetDetent) {
            ElementPropertiesSheet(viewModel: viewModel)
                .presentationDetents([.height(Self.propertiesSheetHeight), .large], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                // Sayfa açıkken de canvas'a dokunup başka eleman seçilebilsin.
                .presentationBackgroundInteraction(.enabled(upThrough: .height(Self.propertiesSheetHeight)))
        }
        .overlay {
            if let drag = catalogDrag, let mapping = canvasMapping {
                CatalogDragGhost(element: drag.element, location: drag.location, scale: mapping.scale)
            }
        }
        // Önizleme sayfaların kopyasıyla bu sayfadan açılır; ayrı sayfa değil, kart yerinde büyür
        .overlay {
            if isPreviewing {
                PreviewView(screens: project.previewScreens,
                            startID: viewModel.screen.id,
                            cardFrame: canvasCardFrame,
                            onClose: { isPreviewing = false })
            }
        }
    }

    /// Katalogdan eleman ekler. `point` (normalize) verilirse eleman oraya ortalanır, yoksa görünen alana düşer.
    /// Sembolde önce sembol seçilir; eleman seçimden sonra eklenir.
    private func add(_ type: ElementType, at point: CGPoint?) {
        if type == .symbol {
            wantsProperties = false
            symbolDropPoint = point
            isPickingSymbol = true
        } else {
            viewModel.addElement(of: type, centeredAt: point)
        }
    }

    /// Kapanan sayfa bir dahaki sefere yine yarım boy açılsın.
    private func resetSheetDetent() {
        sheetDetent = .height(Self.propertiesSheetHeight)
    }

    /// `-openProperties <tür>` ile açıldıysa o türdeki ilk elemanı seçip Özellikler sayfasını açar;
    /// `-openProperties background` Arka Plan sayfasını açar (sadece DEBUG).
    private func openPropertiesForDebugIfNeeded() async {
        guard let target = DebugLaunchOptions.propertiesTarget, !DebugLaunchOptions.hasOpenedProperties else { return }
        DebugLaunchOptions.hasOpenedProperties = true
        // Editöre geçiş animasyonu bitmeden açılan sayfa gösterilmiyor.
        try? await Task.sleep(for: .milliseconds(700))

        if target == DebugLaunchOptions.background {
            isEditingBackground = true
        } else if let type = ElementType(rawValue: target),
                  let element = viewModel.screen.elements.first(where: { $0.type == type }) {
            viewModel.select(element.id)
            wantsProperties = true
        }
    }

    /// Katalogları yükleyip verilen ekranla bir editör hazırlar.
    /// Katalog okunamazsa boş katalogla açılır (çökmez).
    private static func makeEditor(screen: PrototypeScreen) -> EditorViewModel {
        guard let catalog = try? ComponentCatalog.load() else {
            return EditorViewModel(catalog: .empty, screen: screen)
        }
        let symbols = (try? SymbolCatalog.load()) ?? .empty
        let images = (try? ImageLibrary.load()) ?? .empty
        return EditorViewModel(catalog: catalog,
                               symbolCatalog: symbols,
                               imageLibrary: images,
                               screen: screen)
    }
}

#Preview {
    let container = try! ModelContainer(for: Project.self, ScreenRecord.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let project = Project.create(name: "Önizleme",
                                 screen: MockScreens.login(using: try! ComponentCatalog.load()),
                                 in: container.mainContext)
    return NavigationStack {
        EditorView(project: project, record: project.sortedScreens[0])
    }
    .modelContainer(container)
}
