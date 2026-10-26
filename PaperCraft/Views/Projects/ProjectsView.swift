//
//  ProjectsView.swift
//  PaperCraft
//

import SwiftData
import SwiftUI

/// Uygulamanın açılış ekranı "Projelerim": projeler, yeni proje, yeniden adlandırma ve silme.
/// Bir projeye dokununca editör açılır.
struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    /// En son düzenlenen en üstte.
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]

    /// Açık olan editör(ler); yeni proje oluşturunca doğrudan editöre geçmek için.
    @State private var path: [Project] = []
    /// Adı değiştirilen proje ve yazılan yeni ad.
    @State private var renamingProject: Project?
    @State private var newName = ""
    /// Silinmesi onay bekleyen proje.
    @State private var deletingProject: Project?

    /// Örnek proje bir kez oluşturulur; kullanıcı silerse geri gelmez.
    @AppStorage("hasCreatedSampleProject") private var hasCreatedSampleProject = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 20)]

    var body: some View {
        NavigationStack(path: $path) {
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
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .navigationDestination(for: Project.self) { project in
                EditorView(project: project)
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
        .task { createSampleProjectIfNeeded() }
    }

    // MARK: - Parçalar

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // İki Text'i `+` ile birleştiriyoruz: nokta farklı renkte.
                (Text("papercraft").foregroundStyle(Theme.ink)
                 + Text(".").foregroundStyle(Theme.accent))
                    .font(Theme.logoFont(size: 24))
                Spacer()
                Button(action: createProject) {
                    Label("Yeni proje", systemImage: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.paper)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("n", modifiers: .command)
            }
            Text("Projelerim")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.ink)
        }
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

    // MARK: - İşlemler

    /// Boş bir ekranla yeni proje açar ve doğrudan editörüne geçer.
    private func createProject() {
        let name = Project.uniqueName("Yeni Proje", existing: projects.map(\.name))
        let project = Project.create(name: name, screen: PrototypeScreen(name: "Ekran 1"), in: context)
        path.append(project)
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
