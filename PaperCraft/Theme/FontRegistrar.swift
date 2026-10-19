//
//  FontRegistrar.swift
//  PaperCraft
//

import CoreText
import Foundation

/// Uygulama paketindeki font dosyalarını (.ttf / .otf) sisteme tanıtır.
/// Uygulama açılırken bir kez çağrılır; Info.plist'e font eklemeye gerek kalmaz.
enum FontRegistrar {

    /// Paketteki tüm fontları kaydeder ve kaç dosya bulunduğunu döndürür.
    @discardableResult
    static func registerBundledFonts(in bundle: Bundle = .main) -> Int {
        let fontURLs = ["ttf", "otf"].flatMap { fileExtension in
            bundle.urls(forResourcesWithExtension: fileExtension, subdirectory: nil) ?? []
        }
        for url in fontURLs {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        return fontURLs.count
    }
}
