//
//  ProjectsView.swift
//  PaperCraft
//

import SwiftData
import SwiftUI

/// Uygulamanın açılış ekranı "Projelerim": projeler, yeni proje, yeniden adlandırma ve silme.
/// Bir projeye dokununca sayfaları açılır.
struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    /// Geniş ekranda (iPad, tam ekran) proje listesi solda, seçili projenin sayfaları sağda.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// En son düzenlenen en üstte.
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]

    /// Açık olan proje ve sayfa; yeni proje oluşturunca doğrudan editöre geçmek için.
    @State private var path = NavigationPath()
    /// Adı değiştirilen proje ve yazılan yeni ad.
    @State private var renamingProject: Project?
    @State private var newName = ""
    /// Silinmesi onay bekleyen proje.
    @State private var deletingProject: Project?
    /// ⓘ ile açılan Lisanslar sayfası
    @State private var isShowingLicenses = false
    /// iPad: soldaki listede seçili proje. `nil` ya da silinmişse en son düzenlenen seçili görünür.
    @State private var selectedProjectID: PersistentIdentifier?
    /// iPad: "Dene" ile önizlemesi açılan proje ve büyümeye başladığı ilk sayfa kartının yeri.
    @State private var previewProject: Project?
    @State private var previewCardFrame: CGRect = .zero

    /// Örnek proje bir kez oluşturulur; kullanıcı silerse geri gelmez.
    @AppStorage("hasCreatedSampleProject") private var hasCreatedSampleProject = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 20, alignment: .top)]
    // .top: iPad kartı daha kısa; satırda ortalanmasın.

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if isWide {
                    wideLayout
                } else {
                    compactLayout
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .navigationDestination(for: Project.self) { project in
                ProjectPagesView(project: project, onOpen: { path.append($0) })
            }
            .navigationDestination(for: ScreenRecord.self) { record in
                if let project = record.project {
                    EditorView(project: project, record: record)
                }
            }
        }
        .alert("Yeniden adlandır", isPresented: isRenaming) {
            TextField("Proje adı", text: $newName)
            Button("Kaydet") { rename() }
            Button("Vazgeç", role: .cancel) {}
        }
        .confirmationDialog("Bu proje silinsin mi?", isPresented: isDeleting, titleVisibility: .visible) {
            Button("Sil", role: .destructive) { delete() }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("\"\(deletingProject?.name ?? "")\" ve tüm ekranları silinir. Bu geri alınamaz.")
        }
        .sheet(isPresented: $isShowingLicenses) {
            LicensesView()
        }
        .task {
            createSampleProjectIfNeeded()
            removeUnusedImages()
            openEditorForDebugIfNeeded()
        }
    }

    // MARK: - Parçalar

    /// Geniş ekran mı? Bölünmüş ekranda dar kalan iPad penceresi iPhone düzenine döner.
    private var isWide: Bool {
        horizontalSizeClass == .regular
    }

    /// iPhone: projeler ızgara halinde; dokununca sayfaları yeni ekranda açılır.
    private var compactLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if projects.isEmpty {
                    emptyState
                } else {
                    projectGrid
                }
            }
            .padding(20)
        }
        .background(Theme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // İki Text'i `+` ile birleştiriyoruz: nokta farklı renkte.
                (Text("papercraft").foregroundStyle(Theme.ink)
                 + Text(".").foregroundStyle(Theme.accent))
                    .font(Theme.logoFont(size: 24))
                Spacer()
                Button { isShowingLicenses = true } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Lisanslar")
                newProjectMenu(compact: false)
            }
            Text("Projelerim")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.ink)
        }
    }

    /// "Yeni proje": dokununca cihaz seçilir. Kullanıcının elindeki cihaz en üstte.
    /// `compact` iPad kenar listesinde yalnızca + gösterir; dar sütunda logo ile yan yana sığsın.
    private func newProjectMenu(compact: Bool) -> some View {
        Menu {
            ForEach(DeviceKind.menuOrder(preferred: currentDevice), id: \.self) { device in
                Button(device.title, systemImage: device.symbolName) {
                    createProject(device: device)
                }
            }
        } label: {
            Label("Yeni proje", systemImage: "plus")
                .labelStyle(NewProjectLabelStyle(compact: compact))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.paper)
                .padding(.horizontal, compact ? 0 : 16)
                .frame(width: compact ? 44 : nil, height: 44)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 10))
        }
        .accessibilityLabel("Yeni proje")
        .menuStyle(.button)
        .buttonStyle(.plain)
        // ⌘N menüyü açmadan bu cihaz için proje açar.
        .background {
            Button("Yeni proje") { createProject(device: currentDevice) }
                .keyboardShortcut("n", modifiers: .command)
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// Uygulamanın çalıştığı cihaz; Mac'te iPhone.
    private var currentDevice: DeviceKind {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
        #else
        .iPhone
        #endif
    }

    private var projectGrid: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
            ForEach(projects) { project in
                NavigationLink(value: project) {
                    ProjectCard(project: project)
                }
                .buttonStyle(.plain)
                // Uzun basınca (Mac'te sağ tık) çıkan menü
                .contextMenu {
                    Button("Yeniden adlandır", systemImage: "pencil") {
                        newName = project.name
                        renamingProject = project
                    }
                    Button("Sil", systemImage: "trash", role: .destructive) {
                        deletingProject = project
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.dashed")
                .font(.system(size: 44))
            Text("Henüz projen yok")
                .font(.system(size: 18, weight: .semibold))
            Text("\"Yeni proje\" ile ilk ekranını tasarlamaya başla.")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Theme.ink.opacity(0.7))
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - iPad düzeni

    /// iPad: solda proje listesi, sağda seçili projenin sayfaları. Sayfaya dokununca editör tüm ekrana açılır.
    /// `NavigationSplitView` değil: editör bu yığının içinde açılıyor, iç içe yığın editörü kapatıyordu.
    private var wideLayout: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 320)
            Rectangle()
                .fill(Theme.ink.opacity(0.12))
                .frame(width: 1)
                .ignoresSafeArea()
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.background)
        .overlay {
            // Önizleme sağ tarafa değil tüm ekrana açılır
            if let project = previewProject, let first = project.previewScreens.first {
                PreviewView(screens: project.previewScreens,
                            startID: first.id,
                            canvasSize: project.device.canvasSize,
                            cardFrame: previewCardFrame,
                            onClose: { previewProject = nil })
            }
        }
    }

    /// Seçili proje; seçim yoksa ya da seçilen silindiyse en son düzenlenen.
    private var selectedProject: Project? {
        projects.first { $0.persistentModelID == selectedProjectID } ?? projects.first
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    (Text("papercraft").foregroundStyle(Theme.ink)
                     + Text(".").foregroundStyle(Theme.accent))
                        .font(Theme.logoFont(size: 24))
                    Spacer()
                    Button { isShowingLicenses = true } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Lisanslar")
                    newProjectMenu(compact: true)
                }
                Text("Projelerim")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(projects) { project in
                        sidebarRow(project)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 20)
            }
        }
        .background(Theme.panel)
    }

    private func sidebarRow(_ project: Project) -> some View {
        Button {
            selectedProjectID = project.persistentModelID
        } label: {
            ProjectSidebarRow(project: project, isSelected: project == selectedProject)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Yeniden adlandır", systemImage: "pencil") {
                newName = project.name
                renamingProject = project
            }
            Button("Sil", systemImage: "trash", role: .destructive) {
                deletingProject = project
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let project = selectedProject {
            ProjectPagesView(project: project,
                             onOpen: { path.append($0) },
                             isEmbedded: true,
                             onPreview: { frame in
                                 previewCardFrame = frame
                                 previewProject = project
                             })
                // Başka proje seçilince sayfa ekranının durumu (yeniden adlandırma vb.) sıfırlansın
                .id(project.persistentModelID)
        } else {
            emptyState
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: - İşlemler

    /// Boş bir sayfayla yeni proje açar ve doğrudan editörüne geçer.
    private func createProject(device: DeviceKind) {
        let name = Project.uniqueName("Yeni Proje", existing: projects.map(\.name))
        let project = Project.create(name: name, device: device,
                                     screen: PrototypeScreen(name: "Sayfa 1"), in: context)
        // iPad'de proje soldan seçilir, sayfaları zaten sağda; yalnızca editör açılır.
        if isWide {
            selectedProjectID = project.persistentModelID
        } else {
            path.append(project)
        }
        if let record = project.sortedScreens.first { path.append(record) }
    }

    private func rename() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        // Boş ad kaydedilmez; eski ad kalır.
        if let renamingProject, !trimmed.isEmpty {
            renamingProject.name = trimmed
        }
    }

    private func delete() {
        if let deletingProject {
            context.delete(deletingProject)
        }
    }

    /// İlk açılışta uygulamanın neye benzediğini göstermek için örnek "Giriş" projesi.
    private func createSampleProjectIfNeeded() {
        guard !hasCreatedSampleProject else { return }
        hasCreatedSampleProject = true
        guard projects.isEmpty, let catalog = try? ComponentCatalog.load() else { return }
        Project.create(name: "Örnek: Giriş Ekranı", screen: MockScreens.login(using: catalog), in: context)
    }

    /// Silinen proje ve elemanlardan kalan fotoğraf dosyalarını siler. Açılışta bir kez çalışır;
    /// o an hiçbir editör açık olmadığı için geri al ile dönecek bir eleman da yoktur.
    /// Projeler `@Query` yerine doğrudan okunur: liste henüz dolmadıysa boş görünüp her şeyi sildirmesin.
    private func removeUnusedImages() {
        guard let allProjects = try? context.fetch(FetchDescriptor<Project>()),
              let usedNames = Project.uploadedImageNames(in: allProjects) else { return }
        UploadedImageStore.shared.removeUnused(keeping: usedNames)
    }

    /// `-openEditor` / `-openProperties` ile açıldıysa en son projenin ilk sayfasına gider (sadece DEBUG).
    private func openEditorForDebugIfNeeded() {
        guard DebugLaunchOptions.opensEditor, !DebugLaunchOptions.hasOpenedEditor else { return }
        let newestFirst = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        guard let project = try? context.fetch(newestFirst).first,
              let record = project.sortedScreens.first else { return }
        DebugLaunchOptions.hasOpenedEditor = true
        if isWide {
            selectedProjectID = project.persistentModelID
        } else {
            path.append(project)
        }
        path.append(record)
    }

    // MARK: - Uyarı bağlantıları

    private var isRenaming: Binding<Bool> {
        Binding(get: { renamingProject != nil }, set: { if !$0 { renamingProject = nil } })
    }

    private var isDeleting: Binding<Bool> {
        Binding(get: { deletingProject != nil }, set: { if !$0 { deletingProject = nil } })
    }
}

#Preview {
    ProjectsView()
        .modelContainer(for: [Project.self, ScreenRecord.self], inMemory: true)
}
