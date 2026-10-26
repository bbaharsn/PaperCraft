# Kağıttan Dijital iOS/iPadOS/macOS Taslağına: Uygulama Geliştirme Yol Haritası (v2)

Bu doküman, kağıt üzerindeki el çizimlerini (wireframe/sketch) yapay zeka ile algılayıp sürüklenebilir ve düzenlenebilir native iOS, iPadOS ve macOS prototiplerine dönüştüren çoklu platform uygulamasının adım adım geliştirme rehberidir.

> **v2 notu:** Bu sürüm, orijinal yol haritasının risk analizi sonrası güncellenmiş halidir. Neyin neden değiştiği en alttaki **Değişiklik Günlüğü** bölümündedir.

---

## 📌 Proje Özeti & Temel Mantık
* **Girdi:** iPhone/iPad kamerasıyla çekilen veya fotoğraflardan seçilen kağıt üzerindeki arayüz çizimi.
* **İşleme:** Vision LLM ile arayüz elemanlarının (Button, TextField, Switch vb.) tespiti.
* **Çıktı:** SwiftUI üzerinde çalışan; elemanları sürüklenebilir, metinleri değiştirilebilir, silinebilir veya yeni eleman eklenebilir, ekranlar arası geçişli canlı prototip.
* **Senkronizasyon:** Kullanıcı aynı Apple hesabıyla iPhone'da oluşturduğu taslağı iPad ve Mac'te açıp düzenleyebilir (iCloud).

## 🎯 Öncelik Sırası
1. **iPhone** — ana hedef, tüm özellikler önce burada çalışır.
2. **iPad** — aynı özellikler, sadece farklı görünüm düzenleri.
3. **macOS** — en son; kamera yok, iCloud'dan gelen projeleri düzenleme odaklı.

## 🧭 Desteklenen Platformlar & Minimum Sürümler
* iPhone, iPad, Mac (native macOS — Mac Catalyst **değil**). visionOS desteklenmez.
* Minimum: **iOS / iPadOS 17.6**, **macOS 14.6** (SwiftData, `@Observable` ve `.inspector` için gereken en düşük sürüm).

---

## Phase 0: Proje Hijyeni (Kısa)
> **Amaç:** Kod yazmaya başlamadan önce proje ayarlarını doğru hale getirmek.

- [x] **Platform temizliği:** visionOS desteğini kaldır (Supported Destinations'dan Apple Vision çıkarılır).
- [x] **Minimum sürüm:** iOS 17.6 / macOS 14.6'ya düşürüldü.
- [x] **Test target'ı:** Swift Testing ile `PaperCraftTests` target'ı eklendi.
- [ ] **Gizli anahtarlar:** API anahtarları için git'e girmeyen bir `Secrets.xcconfig` dosyası ve `.gitignore` kuralı hazırla. *(`.gitignore` kuralı var; dosyanın kendisi henüz yok.)*
- [ ] **Swift dil modu:** Proje boşken Swift 6 moduna geçip geçmeyeceğine karar ver (varsayılan `MainActor` izolasyonu açık; ağ ve görüntü işleme ana thread dışında yapılmalı).

---

## Phase 1: Veri Mimarisi, JSON Kataloğu & AI Keşfi (Spike)
> **Amaç:** Platformdan bağımsız veri modelini kurmak ve modelin AI'ın gerçekten üretebildiği çıktıya uygun olduğunu erkenden doğrulamak.

- [ ] **Veri Modeli:** *(Kısmen: `Project` → `ScreenRecord` → `PrototypeScreen` → `CanvasElement[]`, `NormalizedFrame`, `ElementProperties`, `.unknown` yedeği ve kayıtta `schemaVersion` hazır. Eksik: `action`. `zIndex` yerine dizi sırası kullanılıyor.)*
  * Hiyerarşi: `Project` → `Screen[]` → `Element[]`.
  * `Element`: `id`, `type`, `frame` (**normalize 0…1 koordinatlar**), `properties` (metin, ikon, stil), `zIndex`, opsiyonel `action` (ör. başka bir ekrana git).
  * Referans cihaz çerçevesi (ör. 393×852 pt); normalize koordinatlar ekranda bu çerçeveye göre çizilir.
  * Bilinmeyen eleman tipleri için `.unknown` yedeği — parser asla çökmez.
  * JSON'da `schemaVersion` alanı — eski kayıtlar ileride açılabilsin.
- [x] **Eleman Kataloğu (JSON):** `Text`, `Button`, `TextField`, `Image`, `Switch`, `Slider`, `NavigationBar`, `TabBar` için varsayılan boyut, metin ve stil değerleri → `PaperCraft/Resources/Catalog/ComponentCatalog.json`.
- [x] **SF Symbols Haritası (JSON):** 58 sık kullanılan ikon, Türkçe/İngilizce anahtar kelimelerle → `PaperCraft/Resources/Catalog/SymbolCatalog.json`.
- [ ] **Katalog Swift Modelleri:** JSON'ları okuyan `Codable` modeller + çalışma anında sembol adı doğrulama; geçersizse `fallbackSymbol`'e düş. *(Kısmen: `ComponentCatalog`, `SymbolCatalog` ve `ImageLibrary` modelleri hazır ve test edildi. Eksik: sembol adını çalışma anında doğrulayıp `fallbackSymbol`'e düşme henüz kullanılmıyor.)*
- [ ] **Kalıcılık & iCloud Senkronizasyonu:** *(Kısmen: SwiftData hazır — `Project` ve `ScreenRecord` iCloud kurallarına uygun, ekran JSON olarak saklanıyor, `schemaVersion` var. Eksik: CloudKit'i açmak; yüklenen fotoğraflar şu an sadece cihazda.)*
  * SwiftData + CloudKit. `Project` ve `Screen` SwiftData kayıtları; eleman listesi kayıt içinde JSON verisi olarak saklanır (CloudKit kısıtlarıyla daha az sorun çıkarır).
  * CloudKit kuralları: tüm alanlar opsiyonel veya varsayılan değerli, `unique` kısıtı yok, ilişkiler opsiyonel.
- [x] **Geri Al / Yinele Altyapısı:** Model değişiklikleri tek bir noktadan geçer. *(`EditorViewModel.screen` her değiştiğinde eski hal yığına girer; hızlı art arda değişiklikler tek adım, en fazla 50 adım. `UndoManager` yerine kendi yığınımız; üst barda butonlar, ⌘Z / ⌘⇧Z.)*
- [x] **MVVM:** Model ve ViewModel'ler platformdan bağımsız; tüm cihazlar aynı katmanı kullanır. *(`EditorViewModel`)*
- [ ] **AI Spike (kod dışı deney):**
  * 10–15 gerçek el çizimi topla (bu set ileride doğruluk testi için sabit kalır).
  * Seçilen AI sağlayıcısına gönder, JSON çıktılarını incele: koordinat isabeti, tip doğruluğu, metin okuma.
  * Sonuçlara göre veri şemasını kesinleştir.
- [ ] **Testler:** JSON encode/decode, bilinmeyen tip, eski şema sürümü için birim testleri. *(Kısmen: 96 test; bilinmeyen tip ve bilinmeyen değerlerin varsayılana düşmesi, bozuk kaydın boş ekran olarak açılması test ediliyor. Eksik: eski `schemaVersion`'lı bir kaydı açma testi — ilk şema değişikliğinde yazılacak.)*

---

## Phase 2: Tasarım Sistemi & iPhone UX
> **Amaç:** Kodlamaya geçmeden önce uygulamanın görsel kimliğini ve iPhone akışlarını netleştirmek. Veri modeli ve katalog hazır olduğu için tasarım, gerçek eleman tipleri üzerinden yapılır.

- [ ] **Temel Kaynaklar:**
  * Apple Design Resources (iOS UI Kit for Figma, ücretsiz) temel alınır.
  * Mümkün olduğunca native SwiftUI bileşenlerine yaslan; böylece farklı iOS sürümlerinde (17 → 26) tasarım otomatik uyum sağlar.
- [ ] **Mini Tasarım Sistemi:**
  * Renk paleti (açık/koyu mod), tipografi (SF Pro + Dynamic Type), boşluk ölçüleri, köşe yarıçapları, ikon dili.
  * Bu değerler daha sonra koda doğrudan "token" olarak aktarılacak (Assets renkleri + `Theme` sabitleri).
- [ ] **iPhone Ekran Akışları:**
  * **Projelerim:** Kayıtlı taslaklar, `+ Yeni Taslak` butonu, boş durum (hiç proje yokken) tasarımı.
  * **Girdi:** Kamera ile tara / Fotoğraflardan seç seçenekleri. (Tarama ekranını sistem sağladığı için özel kamera arayüzü tasarlamaya gerek yok.)
  * **Analiz:** AI işlerken gösterilecek tarama animasyonu; hata ve "tekrar dene" durumları.
  * **Editör:** Canvas, seçim çerçevesi, hızlı işlem menüsü (Sil, Klonla, Düzenle), alt panel (inspector), Eleman Kütüphanesi (palette), Geri Al/Yinele butonları.
  * **Ekranlar:** Bir projedeki ekranların listesi ve ekranlar arası bağlantı kurma.
  * **Önizleme:** Editör çizgilerinin kaybolduğu canlı prototip modu.
- [ ] **Etkileşim Kuralları:** Tek dokunuş = seç, sürükle = taşı, uzun bas = menü, iki parmak = yakınlaştır/kaydır. Bu kurallar yazılı hale getirilir.
- [ ] **iPad Varyantı (taslak):** Aynı ekranların geniş düzeni — sol menü, ortada Canvas, sağda sabit Özellikler Paneli. Detaylandırma Phase 5'te.
- [ ] **Çıkış Kriteri:** iPhone ekranlarının tamamı onaylandı + tasarım token listesi hazır.

---

## Phase 3: iPhone Uygulaması — Canvas & Editör
> **Amaç:** iPhone'da çalışan dinamik tuval ve düzenleme altyapısını kurmak. Yapı baştan adaptif kurulur ki iPad ve Mac'te yeniden yazılmasın.

- [ ] **Uygulama İskeleti:** *(Kısmen: renkler, ölçüler ve logo fontu `Theme`'de; Projelerim → Editör gezinmesi `NavigationStack` ile çalışıyor. Eksik: Phase 2 tasarım onayı, iPad için `NavigationSplitView`.)*
  * Phase 2'deki tasarım token'larını koda aktar.
  * Gezinme yapısını `NavigationSplitView` ile kur (iPhone'da otomatik olarak tek sütunlu yığına dönüşür).
- [ ] **Canvas:** *(Kısmen: `CanvasView` mock ekranı render ediyor, normalize ↔ nokta dönüşümü var. Yakınlaştırma ve kaydırma yok.)*
  * Mock JSON'u cihaz çerçevesi içinde render eden `CanvasView`.
  * Normalize koordinat ↔ ekran noktası dönüşümü; yakınlaştırma ve kaydırma.
- [x] **Seçim & Sürükleme:** *(Ayrıca: köşelerden boyutlandırma, görselde döndürme tutamacı (0/90/180/270°'ye yapışır), son dokunulan eleman en üste gelir.)*
  * Dokunulan eleman `selectedElement` olur, etrafına çerçeve çizilir.
  * Sürükleme sırasında geçici durum (`@GestureState`); model ve geri al kaydı yalnızca sürükleme bitince güncellenir (performans).
- [ ] **Düzenleme Araçları (Alt Panel):** *(Kısmen: 8 elemanın hepsinin Özellikler sayfası var (çift dokunuşla açılır, değişiklik anında canvas'a yansır); Sil, Çoğalt (⌘D), geri al / yinele; katalogdan dokunarak ekleme. Eksik: katalogdan sürükle-bırak.)*
  * Seçili elemanın metnini, rengini veya ikonunu değiştiren alt panel (`.sheet` + `presentationDetents`).
  * Silme, klonlama, geri al / yinele.
  * Paletten ekleme: önce **dokunarak ekleme**, ardından sürükle-bırak.
- [ ] **Görseller:** *(Kısmen: hazır görsel kütüphanesi — Microsoft Fluent Emoji'den 28 yiyecek-içecek görseli (MIT), renkli ya da tek renk + renk seçimi; fotoğraf yükleme (`PhotosPicker`, en fazla 2048 px PNG) ve cihazda arka plan silme (Vision, simülatörde çalışmaz). Eksik: diğer kategoriler; MIT lisans metnini gösteren "Lisanslar" ekranı (yayından önce şart); silinen proje/elemanların fotoğraf dosyalarını temizleme (çoğaltılan elemanlar aynı dosyayı paylaşıyor).)*
- [ ] **Çoklu Ekran & Önizleme Modu:**
  * Ekran ekleme/silme, elemanlara "şu ekrana git" aksiyonu bağlama.
  * Editör çizgilerinin gizlendiği canlı prototip modu.
- [x] **Kalıcılık:** Projelerim ekranı SwiftData ile çalışır. *(Oluştur, aç, yeniden adlandır, sil; editörde her değişiklik otomatik kaydedilir; ilk açılışta örnek proje.)*

---

## Phase 4: Kamera & Yapay Zeka Entegrasyonu (iPhone)
> **Amaç:** Kağıttaki çizimi algılayıp Canvas'a besleyen akışı uçtan uca çalıştırmak.

- [ ] **Görsel Yakalama:** *(`PhotosPicker` görsel elemanında fotoğraf yüklemek için zaten kullanılıyor; burada çizimi seçmek için yeniden kullanılabilir.)*
  * `VisionKit` — `VNDocumentCameraViewController`: kağıdı otomatik algılar, perspektifi düzeltir ve kırpar.
  * `PhotosPicker`: mevcut fotoğraflardan seçim.
  * Info.plist: `NSCameraUsageDescription` metni.
- [ ] **AI Servis Katmanı:**
  * Sağlayıcıdan bağımsız bir `AIService` protokolü — sağlayıcı değişirse sadece tek bir sınıf değişir.
  * Ağ ve görüntü işleme ana thread dışında çalışır.
  * Yapılandırılmış çıktı (JSON şeması / tool use) ile normalize koordinatlar istenir.
  * Cihaz içi `Vision` metin tanıma (`VNRecognizeTextRequest`) ile etiket metinleri ayrıca okunup AI sonucu desteklenir.
  * Koordinatlar ızgaraya oturtulur (snap) — AI'ın küçük kaymaları düzeltilir.
- [ ] **API Anahtarı Güvenliği:**
  * Geliştirme sırasında: anahtar `Secrets.xcconfig` içinde, git'e girmez.
  * Uygulama başka birine dağıtılmadan önce: anahtar uygulamadan çıkarılır, küçük bir sunucu (proxy) üzerinden istek atılır.
- [ ] **Bileşen Eşleştirme (Parser):** AI çıktısı → Phase 1 veri modeli. Kaydedilmiş gerçek AI yanıtlarıyla birim testleri.
- [ ] **Hata Durumları:** İnternet yok, zaman aşımı, bozuk JSON, hiç eleman bulunamadı → kullanıcıya anlaşılır mesaj, tekrar dene veya boş Canvas ile devam et.
- [ ] **Gizlilik:** Görsel üçüncü taraf AI'a gönderilmeden önce kullanıcıdan bir kerelik açık onay alınır.
- [ ] ~~**CoreML YOLOv8**~~ — v1 kapsamından çıkarıldı (bkz. Değişiklik Günlüğü).

---

## Phase 5: iPad Düzenleri (Regular Layout)
> **Amaç:** Aynı özellikleri iPad'in geniş ekranına uygun düzenlerle sunmak.

- [ ] **Çok Sütunlu Düzen:** Sol menü (projeler/ekranlar), orta alan (Canvas), sağ panel (`.inspector`).
- [ ] **Size Class Mantığı:** Yalnızca `@Environment(\.horizontalSizeClass)` kullanılır (`UIDevice` macOS'ta derlenmediği için kullanılmaz). Regular'da sabit panel, Compact'ta alt panel.
- [ ] **Split View / Stage Manager Testi:** Pencere daraldığında iPhone düzenine geçiş; seçili eleman ve açık panel durumu kaybolmamalı (durum ViewModel'de tutulur).
- [ ] **Donanım Klavyesi:** Temel kısayollar (Sil, ⌘Z, ⌘⇧Z, ⌘D) — Mac ile ortak kullanılır. *(Kısmen: ⌘Z, ⌘⇧Z, ⌘D ve Projelerim'de ⌘N var. Eksik: Sil tuşu.)*

---

## Phase 6: macOS Desteği
> **Amaç:** Kullanıcının iPhone'da oluşturduğu projeleri Mac'te açıp düzenleyebilmesi.

- [ ] **Senkronizasyon Odaklı Kullanım:** Projeler iCloud üzerinden gelir; Mac'te kamera kullanılmaz (kamera izni gerekmez).
- [ ] **Opsiyonel Görsel İçe Aktarma:** Dosya sürükle-bırak ile çizim görseli ekleme (AI analizi Mac'te de isteniyorsa).
- [ ] **Yetkiler (Sandbox):** iCloud/CloudKit; AI Mac'te de kullanılacaksa "Outgoing Connections (Client)".
- [ ] **Platforma Özel Kod:** Yalnızca `#if os(macOS)` (proje native macOS, Catalyst değil).
- [ ] **Masaüstü Deneyimi:** Fare ile seçme/sürükleme, `.commands` menü kısayolları, `.contextMenu` sağ tık menüsü, hover durumları, minimum pencere boyutu.

---

## Phase 7: Test, İnce Ayar & Dışa Aktarma
> **Amaç:** Uygulamayı kararlı hale getirmek ve çıktı alma özelliklerini tamamlamak.

- [ ] **SwiftUI Kod Dışa Aktarma:**
  * **v1:** Ekrandaki konumları birebir koruyan "prototip kodu" (kopyalanabilir `.swift`).
  * **v2 (ileride):** Elemanları satır/sütun olarak gruplayıp `VStack`/`HStack` düzenine çeviren, farklı ekran boyutlarına uyum sağlayan kod.
- [ ] **Performans & Cihaz Testleri:** iPhone (küçük/büyük), iPad (11" / 13"), Mac. Phase 1'deki sabit çizim setiyle AI doğruluk ölçümü.
- [ ] **Yayın (karar ertelendi):** App Store'a çıkılmasına karar verilirse:
  * API proxy'si devrede, anahtar uygulamada yok.
  * Privacy Manifest ve App Privacy etiketi dolduruldu, AI onay ekranı var.
  * Tek bundle ID ile Universal Purchase (iPhone + iPad + Mac).

---

## 🔁 Tüm Aşamalarda Sürekli
* Her aşamanın sonunda birim testleri çalışır durumda olmalı (test en sona bırakılmaz).
* Her aşama ayrı git commit'leri/branch'i ile ilerler.

## ❓ Açık Kararlar
* **AI sağlayıcısı:** Claude / GPT-4o / diğer — Phase 1 AI Spike'tan önce seçilecek.
* **App Store'a çıkış:** Sonra değerlendirilecek.

---

## 📝 Değişiklik Günlüğü (v1 → v2)

| Değişiklik | Gerekçe |
|---|---|
| **Phase 0 eklendi** | visionOS gereksiz açıktı, minimum sürüm 26'ydı, test target'ı ve gizli anahtar düzeni yoktu. |
| **Önce veri mimarisi + JSON kataloğu (Phase 1), ardından tasarım (Phase 2)**; tasarım iPhone odaklı | Uygulamanın temelleri önce atılır; tasarım gerçek eleman kataloğu üzerinden yapılır. |
| **AI Spike Phase 1'e eklendi** | Projenin en riskli kısmı AI doğruluğu. Veri modeli, AI'ın gerçek çıktısı görülmeden kesinleştirilmemeli. |
| **Normalize koordinatlar + referans cihaz çerçevesi** | Farklı ekran boyutlarında (iPhone/iPad/Mac) tutarlı görünüm ve AI çıktısıyla uyum. |
| **Çoklu ekran, iCloud senkronizasyonu, Geri Al/Yinele, şema sürümü eklendi** | Orijinal planda eksikti; sonradan eklemek zor. |
| **AI aşaması Phase 6 → Phase 4** | Ürün erkenden uçtan uca çalışır hale gelir; iPad/Mac'ten önce temel değer doğrulanır. |
| **AVFoundation + VNDetectRectangles → VisionKit Document Camera** | Perspektif düzeltme ve kırpma hazır geliyor; çok daha az kod ve hata riski. |
| **API anahtarı güvenliği ve kullanıcı onayı eklendi** | Uygulamaya gömülü anahtar çalınabilir; görsellerin üçüncü taraf AI'a gönderilmesi açık onay gerektirir. |
| **CoreML YOLOv8 kapsamdan çıkarıldı** | Ultralytics YOLOv8 AGPL-3.0 lisanslı; kapalı kaynak/ticari uygulamada sorun yaratabilir. Gerekirse ileride lisansı uygun bir model değerlendirilir. |
| **`NavigationSplitView` baştan (Phase 3)** | iPhone'u ayrı yazıp sonra iPad'e uyarlamak yeniden yazım demek; bu yapı iPhone'da zaten tek sütun çalışır. |
| **`UIDevice` ve Mac Catalyst ifadeleri kaldırıldı** | Proje native macOS; `UIDevice` macOS'ta derlenmez. |
| **Mac'te kamera kaldırıldı** | Mac'in rolü iPhone'da oluşturulan projeleri düzenlemek. |
| **Export v1/v2 olarak bölündü** | Serbest konumlu düzenden "gerçek" SwiftUI düzen kodu üretmek ayrı ve zor bir problem. |
| **Test sürekli hale getirildi** | Test yalnızca sonda olursa hatalar geç fark edilir. |
