//
//  BackgroundRemover.swift
//  PaperCraft
//

import CoreImage
import Vision

/// Fotoğraftaki ana nesneyi (ürün, insan, hayvan…) arka planından ayırır.
/// Apple'ın Vision'ı cihazda çalışır: internet ya da harici servis gerekmez.
/// Simülatörde çalışmaz (cihazın yapay zekâ çipini kullanır); gerçek iPhone ya da Mac gerekir.
nonisolated enum BackgroundRemover {

    /// Arka planı şeffaf, nesnenin etrafı kırpılmış görsel döner.
    /// Fotoğrafta ayrılacak bir nesne bulunamazsa `nil` döner.
    static func removeBackground(from image: CGImage) throws -> CGImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: image)
        try handler.perform([request])

        guard let result = request.results?.first, !result.allInstances.isEmpty else { return nil }

        // Bulunan tüm nesneleri tut, arka planı şeffaf yap, boşlukları kırp
        let buffer = try result.generateMaskedImage(ofInstances: result.allInstances,
                                                    from: handler,
                                                    croppedToInstancesExtent: true)
        let ciImage = CIImage(cvPixelBuffer: buffer)
        return CIContext().createCGImage(ciImage, from: ciImage.extent)
    }
}
