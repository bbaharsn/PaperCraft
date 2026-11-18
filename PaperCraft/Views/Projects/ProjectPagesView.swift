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
    /// iPad'de Projelerim'in sağ tarafında mı? O zaman geri oku yok, başlık büyük, kartlar daha geniş.
    var isEmbedded = false
    /// Verilirse "Dene" önizlemeyi kendisi açmaz, ilk kartın yeriyle bunu çağırır;
    /// gömülüyken önizleme sağ tarafa değil tüm ekrana açılsın diye.
    var onPreview: ((CGRect) -> Void)? = nil

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

    /// Uzun sayfanın kartı daha uzun; aynı satırdaki kısa kartlar üstten hizalanır.
    /// iPad'de kartlar büyür: iPhone'daki 150 pt'lik kart geniş ekranda küçük pul gibi kalıyordu.
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: isEmbedded ? 190 : 150), spacing: isEmbedded ? 28 : 20, alignment: .top)]
    }

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
                .padding(isEmbedded ? 28 : 20)
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
                            canvasSize: project.device.canvasSize,
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

    @ViewBuilder
    private var topBar: some View {
        if isEmbedded {
            embeddedTopBar
        } else {
            stackTopBar
        }
    }

    /// iPad: solda proje adı başlık olarak (Projelerim başlığıyla aynı ölçü), sağda "Dene".
    private var embeddedTopBar: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("\(project.sortedScreens.count) sayfa · \(project.device.title)")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.ink.opacity(0.65))
            }
            Spacer(minLength: 16)
            tryButton
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }

    /// iPhone: geri oku ve proje adı, sağda "Dene".
    private var stackTopBar: some View {
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

            tryButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var tryButton: some View {
        Button {
            if let onPreview { onPreview(firstCardFrame) } else { isPreviewing = true }
        } label: {
            Text("Dene")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.paper)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func pageCard(_ record: ScreenRecord) -> some View {
        let screen = record.screen ?? PrototypeScreen(name: "Sayfa")
        let isFirst = record == project.sortedScreens.first
        return Button { onOpen(record) } label: {
            VStack(alignment: .leading, spacing: 8) {
                ScreenThumbnail(screen: screen, referenceSize: project.device.canvasSize)
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
                    .aspectRatio(project.device.canvasSize.width / project.device.canvasSize.height, contentMode: .fit)
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
