//
//  EditorView.swift
//  PaperCraft
//
//  Created by Bahar Şen on 13.10.2026.
//

import SwiftData
import SwiftUI

/// Bir projenin editörü: üst bar, canvas, katalog ve Özellikler sayfası.
/// Her değişiklik anında projeye yazılır; "Kaydet" yok.
struct EditorView: View {
    let project: Project
    @State private var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    /// Alt katalog açık mı? Sadece bu ekranı ilgilendiren bir görünüm durumu.
    @State private var isCatalogOpen = false

    /// Kullanıcı Özellikler sayfasını istedi mi (çift dokunuş)?
    /// Tek dokunuş sadece seçer; sayfa açılmadan taşınır ve boyutlandırılır.
    @State private var wantsProperties = false

    /// Özellikler sayfasının yarım açıkken yüksekliği (point).
    private static let propertiesSheetHeight: CGFloat = 340

    init(project: Project) {
        self.project = project
        _viewModel = State(initialValue: Self.makeEditor(screen: project.firstScreen))
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
                projectName: project.name,
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
                onPreview: { /* T6'da önizleme açılacak */ }
            )
            // Canvas yukarı kaydığında üst barın altından geçsin, üstüne binmesin
            .zIndex(1)
            CanvasView(viewModel: viewModel,
                       onDoubleTap: { wantsProperties = true },
                       // Sayfa açıkken canvas küçülmez; seçili eleman sayfanın altında kalırsa yukarı kayar.
                       bottomInset: isShowingProperties.wrappedValue ? Self.propertiesSheetHeight : 0)
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

            if isCatalogOpen {
                CatalogPanel(
                    catalog: viewModel.catalog,
                    onSelect: { type in
                        viewModel.addElement(of: type)
                    }
                )
                    .transition(.move(edge: .bottom))
            }
        }
        .background(Theme.background)
        // Üst barı kendimiz çiziyoruz; sistemin gezinme çubuğu görünmesin.
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        // Seçim tamamen kalkınca istek de sıfırlanır; yoksa sonraki tek dokunuş sayfayı açardı.
        .onChange(of: viewModel.selectedElementID) { _, newID in
            if newID == nil { wantsProperties = false }
        }
        // Otomatik kaydetme: ekran her değiştiğinde projeye yazılır.
        .onChange(of: viewModel.screen) { _, newScreen in
            project.saveFirstScreen(newScreen)
        }
        // SwiftData kendisi de ara ara kaydeder; editörden çıkarken beklemeden diske yazalım.
        .onDisappear {
            try? context.save()
        }
        .sheet(isPresented: isShowingProperties) {
            ElementPropertiesSheet(viewModel: viewModel)
                .presentationDetents([.height(Self.propertiesSheetHeight), .large])
                .presentationDragIndicator(.visible)
                // Sayfa açıkken de canvas'a dokunup başka eleman seçilebilsin.
                .presentationBackgroundInteraction(.enabled(upThrough: .height(Self.propertiesSheetHeight)))
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
        EditorView(project: project)
    }
    .modelContainer(container)
}
