//
//  UploadedImageTests.swift
//  PaperCraftTests
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import PaperCraft

@MainActor
struct UploadedImageTests {

    /// Her test kendi geçici klasörünü kullanır; gerçek yüklemelere dokunulmaz.
    /// Adda boşluk var: gerçek klasör de "Application Support" (yol `%20` ile kodlanırsa dosyalar bulunmaz).
    private func makeStore() -> UploadedImageStore {
        UploadedImageStore(directory: FileManager.default.temporaryDirectory
            .appending(path: "Uploaded Image Tests \(UUID().uuidString)"))
    }

    /// Verilen boyutta düz renkli bir PNG üretir (fotoğraf yerine).
    private func pngData(width: Int, height: Int) throws -> Data {
        let context = try #require(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                             bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(red: 0.67, green: 0.32, blue: 0.21, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try #require(context.makeImage())

        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }

    @Test func savedImageCanBeReadBack() async throws {
        let store = makeStore()

        let name = try await store.save(try pngData(width: 300, height: 200))

        #expect(name.hasSuffix(".png"))
        let image = try #require(store.image(named: name))
        #expect(image.width == 300)
        #expect(image.height == 200)
    }

    @Test func largeImageIsShrunkKeepingRatio() async throws {
        let store = makeStore()

        let name = try await store.save(try pngData(width: 4000, height: 1000))

        let image = try #require(store.image(named: name))
        #expect(image.width == UploadedImageStore.maxPixelSize)
        #expect(image.height == UploadedImageStore.maxPixelSize / 4)
    }

    @Test func unreadableDataThrows() async {
        let store = makeStore()

        await #expect(throws: UploadedImageStore.StoreError.self) {
            try await store.save(Data("bu bir görsel değil".utf8))
        }
    }

    @Test func missingFileGivesNil() {
        #expect(makeStore().image(named: "yok.png") == nil)
    }

    @Test func backgroundRemovedNameSitsNextToOriginal() {
        #expect(UploadedImageStore.backgroundRemovedName(for: "ABC.png") == "ABC_nobg.png")
    }

    @Test func removeUnusedKeepsOnlyUsedFiles() {
        let store = makeStore()
        func touch(_ name: String) {
            FileManager.default.createFile(atPath: store.directory.appending(path: name).path(percentEncoded: false),
                                           contents: Data())
        }
        func exists(_ name: String) -> Bool {
            FileManager.default.fileExists(atPath: store.directory.appending(path: name).path(percentEncoded: false))
        }
        touch("A.png"); touch("A_nobg.png"); touch("B.png"); touch("B_nobg.png")

        store.removeUnused(keeping: ["A.png"])

        #expect(exists("A.png"))
        #expect(exists("A_nobg.png"))   // kullanılan fotoğrafın arka plansız hali de kalır
        #expect(!exists("B.png"))
        #expect(!exists("B_nobg.png"))
    }

    @Test func backgroundRemovedFileIsFound() {
        let store = makeStore()
        #expect(!store.hasBackgroundRemoved(for: "A.png"))

        FileManager.default.createFile(atPath: store.directory.appending(path: "A_nobg.png").path(percentEncoded: false),
                                       contents: Data())

        #expect(store.hasBackgroundRemoved(for: "A.png"))
    }

    @Test func screenListsUploadedImageNamesOnce() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .image)
        editor.setSelectedUploadedImage("A.png")
        editor.duplicateSelectedElement()          // kopya aynı dosyayı paylaşır
        editor.addElement(of: .image)
        editor.setSelectedUploadedImage("B.png")
        editor.addElement(of: .image)
        editor.setSelectedLibraryImage("croissant") // hazır görsel: dosya değil
        editor.addElement(of: .button)

        #expect(editor.screen.uploadedImageNames == ["A.png", "B.png"])
    }

    @Test func uploadingReplacesLibraryImage() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .image)
        editor.setSelectedLibraryImage("croissant")

        editor.setSelectedUploadedImage("ABC.png")

        let properties = try #require(editor.selectedElement?.properties)
        #expect(properties.uploadedImageName == "ABC.png")
        #expect(properties.removesBackground == false)
        #expect(properties.imageName == nil)
    }

    @Test func pickingLibraryImageRemovesUpload() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .image)
        editor.setSelectedUploadedImage("ABC.png")
        editor.updateSelectedProperties { $0.removesBackground = true }

        editor.setSelectedLibraryImage("croissant")

        let properties = try #require(editor.selectedElement?.properties)
        #expect(properties.imageName == "croissant")
        #expect(properties.uploadedImageName == nil)
        #expect(properties.removesBackground == nil)
    }

    @Test func imageMethodsIgnoreOtherTypes() throws {
        let editor = EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))
        editor.addElement(of: .button)

        editor.setSelectedUploadedImage("ABC.png")

        #expect(editor.selectedElement?.properties.uploadedImageName == nil)
    }
}
