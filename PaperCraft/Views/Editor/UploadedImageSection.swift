//
//  UploadedImageSection.swift
//  PaperCraft
//

import PhotosUI
import SwiftUI

/// Görselin Özellikler sayfasındaki "Fotoğraf" bölümü: fotoğraf yükleme ve arka planı silme.
struct UploadedImageSection: View {
    let viewModel: EditorViewModel
    var store = UploadedImageStore.shared

    @State private var pickerItem: PhotosPickerItem?
    /// Fotoğraf yüklenirken ya da arka plan silinirken açık; o sırada seçenekler kilitlenir.
    @State private var isWorking = false
    @State private var errorMessage: String?

    private var uploadedName: String? {
        viewModel.selectedElement?.properties.uploadedImageName
    }

    var body: some View {
        Section {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label(uploadedName == nil ? "Fotoğraf yükle" : "Başka fotoğraf seç",
                      systemImage: "photo.badge.plus")
            }
            .disabled(isWorking)

            if uploadedName != nil {
                BoolPicker(isOn: removesBackgroundBinding, off: "Arka planlı", on: "Arka plansız")
                    .disabled(isWorking)
            }

            if isWorking {
                HStack {
                    ProgressView()
                    Text("Hazırlanıyor…").foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Fotoğraf")
        } footer: {
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            } else {
                Text("Arka plansız seçince fotoğraftaki ana nesne (ürün, insan, hayvan) ayrılır.")
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await upload(item) }
        }
    }

    private func upload(_ item: PhotosPickerItem) async {
        isWorking = true
        errorMessage = nil
        defer {
            isWorking = false
            pickerItem = nil   // aynı fotoğraf tekrar seçilebilsin
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw UploadedImageStore.StoreError.unreadableImage
            }
            viewModel.setSelectedUploadedImage(try await store.save(data))
        } catch {
            errorMessage = "Fotoğraf açılamadı."
        }
    }

    /// Arka plansız seçilince silinmiş hal ilk kez hazırlanır; hazırlanamazsa seçim arka planlıda kalır.
    private var removesBackgroundBinding: Binding<Bool> {
        Binding(
            get: { viewModel.selectedElement?.properties.removesBackground ?? false },
            set: { isOn in Task { await setRemovesBackground(isOn) } }
        )
    }

    private func setRemovesBackground(_ isOn: Bool) async {
        guard let name = uploadedName else { return }
        errorMessage = nil
        if isOn && !store.hasBackgroundRemoved(for: name) {
            isWorking = true
            defer { isWorking = false }
            do {
                guard try await store.makeBackgroundRemoved(for: name) else {
                    errorMessage = "Fotoğrafta ayrılacak bir nesne bulunamadı."
                    return
                }
            } catch {
                errorMessage = "Arka plan silinemedi. Simülatörde çalışmaz; gerçek iPhone ya da Mac'te dene."
                return
            }
        }
        viewModel.updateSelectedProperties { $0.removesBackground = isOn }
    }
}
