//
//  ProjectPagesView.swift
//  PaperCraft
//

import SwiftData
import SwiftUI

/// Proje açılınca görünen ekran: sayfalar ızgara halinde, sonda yeni sayfa kartı.
/// Karta dokununca o sayfa editörde açılır; uzun basınca yeniden adlandırılır ya da silinir.
struct ProjectPagesView: View {
    let project: Project
    /// Bir sayfanın editörde açılması istenince çağrılır.
    let onOpen: (ScreenRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var isPreviewing = false
    /// İlk sayfa kartının ekrandaki yeri; önizleme buradan büyür.
    @State private var firstCardFrame: CGRect = .zero
    /// Adı değiştirilen sayfa ve yazılan yeni ad.
    @State private var renamingRecord: ScreenRecord?
    @State private var newName = ""
    /// Silinmesi onay bekleyen sayfa.
    @State private var deletingRecord: ScreenRecord?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 20)]

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
                    ForEach(project.sortedScreens) { record in
                        pageCard(record)
                    }
                    addCard
                }
                .padding(20)
            }
        }
        .background(Theme.background)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .overlay {
            if isPreviewing, let first = project.previewScreens.first {
                PreviewView(screens: project.previewScreens,
                            startID: first.id,
                            cardFrame: firstCardFrame,
                            onClose: { isPreviewing = false })
            }
        }
        .alert("Yeniden adlandır", isPresented: isRenaming) {
            TextField("Sayfa adı", text: $newName)
            Button("Kaydet") {
                if let renamingRecord { project.renameScreen(renamingRecord, to: newName) }
            }
            Button("Vazgeç", role: .cancel) {}
        }
        .confirmationDialog("Bu sayfa silinsin mi?", isPresented: isDeleting, titleVisibility: .visible) {
            Button("Sil", role: .destructive) {
                if let deletingRecord { project.deleteScreen(deletingRecord, in: context) }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("\"\(deletingRecord?.screen?.name ?? "")\" silinir ve bu sayfaya giden butonların bağlantısı kalkar.")
        }
    }

    // MARK: - Parçalar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(project.name)
                        .lineLimit(1)
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Projelerim'e dön")

            Spacer(minLength: 8)

            Button { isPreviewing = true } label: {
                Text("Dene")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.paper)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(Theme.ink, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func pageCard(_ record: ScreenRecord) -> some View {
        let screen = record.screen ?? PrototypeScreen(name: "Sayfa")
        let isFirst = record == project.sortedScreens.first
        return Button { onOpen(record) } label: {
            VStack(alignment: .leading, spacing: 8) {
                ScreenThumbnail(screen: screen)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .paperCard()
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                        if isFirst { firstCardFrame = $0 }
                    }
                Text(screen.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
            }
        }
        .buttonStyle(.plain)
        // Uzun basınca (Mac'te sağ tık) çıkan menü
        .contextMenu {
            Button("Yeniden adlandır", systemImage: "pencil") {
                newName = screen.name
                renamingRecord = record
            }
            // Projede en az bir sayfa kalır
            if project.sortedScreens.count > 1 {
                Button("Sil", systemImage: "trash", role: .destructive) {
                    deletingRecord = record
                }
            }
        }
    }

    private var addCard: some View {
        Button { onOpen(project.addScreen()) } label: {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .strokeBorder(Theme.ink.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .aspectRatio(CanvasView.referenceSize.width / CanvasView.referenceSize.height, contentMode: .fit)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                    }
                    .contentShape(Rectangle())
                Text("Yeni sayfa")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                    .padding(.horizontal, 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Yeni sayfa ekle")
    }

    // MARK: - Uyarı bağlantıları

    private var isRenaming: Binding<Bool> {
        Binding(get: { renamingRecord != nil }, set: { if !$0 { renamingRecord = nil } })
    }

    private var isDeleting: Binding<Bool> {
        Binding(get: { deletingRecord != nil }, set: { if !$0 { deletingRecord = nil } })
    }
}
