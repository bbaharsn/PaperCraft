//
//  DebugLaunchOptions.swift
//  PaperCraft
//

import Foundation

/// Simülatörde elle dokunmadan bir ekrana gitmek için açılış parametreleri. Sadece DEBUG derlemesinde okunur;
/// yayınlanan uygulamada hepsi `nil` / `false` döner.
///
/// Kullanım (`xcrun simctl launch <cihaz> com.bahar.PaperCraft …`):
/// - `-openEditor YES` → en son düzenlenen projenin ilk sayfası açılır
/// - `-openProperties image` → editör açılır, o türdeki ilk eleman seçilir ve Özellikler sayfası açılır
///   (tür adları `ElementType` ile aynı: `box`, `button`, `textField` …)
/// - `-openProperties background` → sayfanın Arka Plan ayarları açılır
/// - `-largeSheet YES` → açılan sayfa yarım değil tam boy açılır
///
/// Parametreler `UserDefaults`'a kendiliğinden düşer (`-anahtar değer`).
enum DebugLaunchOptions {
    /// Arka Plan sayfası için kullanılan özel ad
    static let background = "background"

    /// `-openProperties` ile istenen tür ya da `background`.
    static var propertiesTarget: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "openProperties")
        #else
        nil
        #endif
    }

    /// Editör doğrudan açılsın mı? `-openProperties` verildiyse de açılır.
    static var opensEditor: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "openEditor") || propertiesTarget != nil
        #else
        false
        #endif
    }

    static var opensLargeSheet: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "largeSheet")
        #else
        false
        #endif
    }

    /// Açılış başına bir kez uygulanır; editörden geri dönünce tekrar açılmasın.
    static var hasOpenedEditor = false
    static var hasOpenedProperties = false
}
