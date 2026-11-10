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

- [ ] **Veri Modeli:** *(Kısmen: `Project` → `ScreenRecord` → `PrototypeScreen` → `CanvasElement[]`, `NormalizedFrame`, `ElementProperties`, `.unknown` yedeği ve kayıtta `schemaVersion` hazır. `zIndex` yerine dizi sırası kullanılıyor.)*
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
- [ ] **Testler:** JSON encode/decode, bilinmeyen tip, eski şema sürümü için birim testleri. *(Kısmen: 184 test; bilinmeyen tip ve bilinmeyen değerlerin varsayılana düşmesi, bozuk kaydın boş ekran olarak açılması test ediliyor. Eksik: eski `schemaVersion`'lı bir kaydı açma testi — ilk şema değişikliğinde yazılacak.)*

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
- [x] **Canvas:** *(Sayfa dikey kayar (bkz. Kayan sayfa); Özellikler sayfası açılınca kart kaldırılmaz, içerik kaydırılır — yazıların üst barın arkasına binmesi düzeldi. İki parmakla %100–%400 yakınlaştırma (parmakların arasındaki nokta yerinde kalır, Mac'te trackpad'de kıstırma); yakınlaştırılmışken boş yerde tek parmakla kaydırma, kart kenarından fazla kaçmaz; sağ üstteki oran düğmesi kartı yeniden sığdırır. Elemanlar yakınlaştırılmışken de seçilir, taşınır, boyutlandırılır; iki parmak inince başlamış taşıma iptal olur.)*
  * Mock JSON'u cihaz çerçevesi içinde render eden `CanvasView`.
  * Normalize koordinat ↔ ekran noktası dönüşümü; yakınlaştırma ve kaydırma.
- [x] **Seçim & Sürükleme:** *(Ayrıca: köşelerden boyutlandırma, görselde döndürme tutamacı (0/90/180/270°'ye yapışır), son dokunulan eleman en üste gelir.)*
  * Dokunulan eleman `selectedElement` olur, etrafına çerçeve çizilir.
  * Sürükleme sırasında geçici durum (`@GestureState`); model ve geri al kaydı yalnızca sürükleme bitince güncellenir (performans).
- [x] **Düzenleme Araçları (Alt Panel):** *(10 elemanın hepsinin Özellikler sayfası var (katalogda sembol de var: eklerken önce sembol seçilir; ikon, boyut, renk, dolu/çizgi, döndürme, bağlantı; Temel sekmesinde kart, etiket ve daire için kutu: dolgu rengi, şekil (Köşeli / Yuvarlak + köşe kaydırıcısı / Hap / Daire), kenarlık kalınlığı ve rengi, gölge, bağlantı) (çift dokunuşla ya da basılı tutunca açılır, değişiklik anında canvas'a yansır; yazılan yükseklik en fazla bir ekran); Sil, Çoğalt (⌘D), geri al / yinele (hızlı gelen farklı değişiklikler ayrı adım); katalogdan dokunarak ekleme ve sürükle-bırak (kart yukarı çekilince elemanın kendisi parmağın altında canvas boyunda görünür, bırakılan yere ortalanır; canvas dışına bırakılırsa eklenmez; sembolde bırakınca sembol seçilir; üst bar / alt menü yine yerine yapışır); sayfa arka planı (düz renk ya da iki veya üç renkli geçiş, üç yön; Medya sekmesindeki kartla ya da boş yere çift dokunarak açılır). Sonra: katalogdan sürüklerken kartın kenarına gelince sayfa kendiliğinden kaymıyor.)*
  * Seçili elemanın metnini, rengini veya ikonunu değiştiren alt panel (`.sheet` + `presentationDetents`).
  * Silme, klonlama, geri al / yinele.
  * Paletten ekleme: önce **dokunarak ekleme**, ardından sürükle-bırak.
- [ ] **Görseller:** *(Kısmen: hazır görsel kütüphanesi — Microsoft Fluent Emoji'den 28 yiyecek-içecek görseli (MIT), renkli ya da tek renk + renk seçimi; fotoğraf yükleme (`PhotosPicker`, en fazla 2048 px PNG) ve cihazda arka plan silme (Vision, simülatörde çalışmaz); hiçbir elemanın kullanmadığı fotoğraflar açılışta siliniyor (bozuk kayıt varsa hiçbiri silinmez). Yüklenen fotoğrafın şekli seçilir: Köşeli, Yuvarlak (köşe kaydırıcısı), Hap ya da Daire; Daire çerçeve kare olmasa da ortada tam daire çizer ve fotoğrafla doldurur (profil fotoğrafı). Diğer şekillerde "Sığdır" ya da "Doldur". Şekli izleyen kenarlık (kalınlık + renk). Şekil ve kenarlık kutuyla ortak (`frameShape`, `cornerRadius`, `borderWidth`, `borderColor`). Projelerim'deki ⓘ ile açılan "Lisanslar" ekranı Fluent Emoji (MIT) ve logo fontu Bricolage Grotesque (OFL) metinlerini gösteriyor; yeni bir açık kaynak parça eklenince `License.all`'a da eklenmeli. Eksik: diğer kategoriler; iCloud açılınca temizliğin diğer cihazların fotoğraflarını silmemesi.)*
- [ ] **Çoklu Ekran & Önizleme Modu:** *(Kısmen: "Dene" ile canvas kartı büyüyerek tam ekran önizlemeye dönüşür; üst bar her telefonda güvenli alanın altına, alt menü en alta oturur; switch, slider, metin kutusu ve sekmeler dokunuşa tepki verir, butonlar basınca kararır. Önizleme ekranın kopyasıyla çalışır, tasarımı değiştirmez; klavye yazılan kutuyu kapatacaksa tasarım yukarı kayar; ✕ ya da aşağı kaydırmayla kart yerine küçülerek kapanır. Projede birden fazla sayfa var: ızgarada görünür, eklenir, adlandırılır, silinir; buton, görsel, sembol, üst bar sağ butonu ve alt menü sekmelerinin "Dokununca" bölümünden sayfaya gitme ve geri dönme bağlanır, Dene'de sayfalar yandan kayarak geçer. üst barın geri oku da önceki sayfaya döner. Eksik: metin elemanına bağlantı.)*
  * Ekran ekleme/silme, elemanlara "şu ekrana git" aksiyonu bağlama.
  * Editör çizgilerinin gizlendiği canlı prototip modu.
- [x] **Kalıcılık:** Projelerim ekranı SwiftData ile çalışır. *(Oluştur, aç, yeniden adlandır, sil; editörde her değişiklik otomatik kaydedilir; ilk açılışta örnek proje.)*

### 🔍 Örnek Uygulama Analizi (Kasım 2026)
Popüler uygulamaların ekranlarını PaperCraft'ın elemanlarıyla (Yazı, Buton, Metin kutusu, Görsel, Sembol, Kutu, Switch, Slider, Üst bar, Sekme barı + çok sayfa, bağlantı, arka plan) yapabiliyor muyuz?

| Uygulama / ekran | Durum | Nasıl / ne eksik |
|---|---|---|
| Instagram giriş | ✅ | Logo görsel, iki metin kutusu, buton, "Şifremi unuttum" yazısı |
| Ayarlar (iPhone Ayarlar gibi) | ✅ | Her satır = Kutu + Sembol + Yazı + Switch; satırları tek tek dizmek zahmetli |
| Spotify "Şimdi çalıyor" | ✅ | Kapak görsel, şarkı adı, ilerleme Slider, ⏮ ⏯ ⏭ sembolleri, koyu arka plan |
| Hava durumu | ✅ | Geçişli arka plan, büyük derece yazısı, sembollerle saatlik satır |
| Duolingo ders sorusu | ✅ | Soru yazısı, şık butonları, "Kontrol et" butonu, ince Kutu ile ilerleme |
| WhatsApp sohbet | 🟡 | Balonlar Kutu + Yazı; yuvarlak profil fotoğrafı artık var; mesaj listesi kaymıyor |
| Getir / Yemeksepeti ana sayfa | 🟡 | Kategori kartları Kutu + Görsel; sayfa ekran boyundan uzun olamıyor, yatay şerit yok |
| Instagram akış | 🟡 | Tek gönderi olur; hikâye halkası (yuvarlak foto + kenarlık) ve kayan akış yok |
| Banka uygulaması | 🟡 | Bakiye kartı ve butonlar olur; işlem listesi kaymıyor, grafik yok |
| Uber / BiTaksi | 🔴 | Ekranın çoğu harita; alttan açılan sayfa yok |
| YouTube / TikTok | 🔴 | Video ve tam ekran dikey akış yok; kapak görseliyle taklit edilebilir |

Bu analizden çıkan eksikler (önem sırasıyla):
- [x] **Yuvarlak / köşeli görsel:** Yüklenen fotoğrafa ve kutuya ortak şekil seçimi (Köşeli / Yuvarlak / Hap / Daire) + fotoğrafta Sığdır / Doldur. *(Profil fotoğrafı, ürün kartı, ikon zemini. Yuvarlak ikon butonu için Buton'un Daire şekli zaten var: ikon seçilince sadece ikon görünür.)*
- [x] **Kayan sayfa:** Kart telefon boyunda kalır, içerik kayar. Editörde boş yerde sürükleyince sayfa kayar (büyütülmüşse önce kart), kaydırmanın sonunda her zaman bir boş ekran daha var; sayfanın gerçek uzunluğu en alttaki elemanın 24 pt altında biter ve editörde "Sayfa sonu" kesik çizgisiyle görünür. Katalogdan eklenen eleman görünen alana gelir; eleman kartın alt/üst kenarına sürüklenince sayfa kendiliğinden kayar. Üst bar ve alt menüde "Kaydırınca: Sabit / Sayfayla kayar". Dene'de uzun sayfa kayar, sabit barlar yerinde kalır, aşağı çekip kapatma sadece en üstteyken. Sayfa kartı en fazla 2 ekran boyu uzar, fazlası soluklaşır. Tasarım: `docs/superpowers/specs/2026-11-08-scrolling-page-design.md`. *(Eksik: uzun sayfada Dene'de klavye yazılan kutuyu kaldırmıyor.)*
- [ ] **Tekrarlayan satır / liste:** Aynı satırı elle dizmek yerine "çoğalt ve alta diz" ya da bir liste elemanı.
- [ ] **Alttan açılan sayfa / açılır pencere:** Dene'de bir sayfayı sheet ya da uyarı olarak açma (Uber, Haritalar, "Emin misin?").
- [ ] **Daha seyrek gerekenler:** segment seçici, sayfa noktaları (onboarding), hikâye halkası (kenarlıkla fotoğraf arasında boşluk), harita görseli, grafik.

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
