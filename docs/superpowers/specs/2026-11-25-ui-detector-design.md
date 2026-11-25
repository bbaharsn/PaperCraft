# Görselden Ekran Oluşturma: Kendi Eğittiğimiz UI Tespit Modeli — Tasarım

**Tarih:** 2026-11-25
**Durum:** Taslak (onay bekliyor)

## Amaç ve neden

Kullanıcı bir ekran görüntüsü ya da dijital wireframe yükler. PaperCraft bu görseldeki arayüz elemanlarını (buton, yazı kutusu, switch…) bulur ve onları düzenlenebilir canvas elemanlarına çevirir.

Bu işi hazır bir API yerine **kendi eğittiğimiz bir modelle** yapıyoruz. İki sebebi var:

1. **Öğrenmek:** Bahar, ML'in temel döngüsünü baştan sona kendisi yapmayı öğrenmek istiyor: veri hazırlama → eğitim → ölçüm → uygulamaya koyma.
2. **CV:** "Custom object detection model trained on ~4.8k UI screenshots, deployed on-device with Core ML" gibi somut, ölçülebilir bir madde.

Kullanıcıların çoğunlukla **dijital görsel** yükleyeceği varsayılıyor. El çizimi ayrı olarak araştırılacak.

## Hedefler

- VINS datasetiyle (`~/Downloads/All Dataset`) bir YOLO nesne tespit modeli eğitmek.
- Modelin başarısını hiç görmediği test verisiyle sayılarla ölçmek (precision, recall, mAP) ve sonucu yazmak.
- Modeli Core ML'e çevirip PaperCraft'ta **cihaz içinde, internetsiz** çalıştırmak.
- iPhone'da kullanıcı fotoğraflardan bir görsel seçer **ya da kamerayla bir tasarımın fotoğrafını çeker** (başka bir ekranda, kağıt çıktıda). Ardından yeni bir ekran oluşur ve bulunan elemanlar canvas'a yerleşir.

## Hedef olmayanlar (bu aşamada)

- **El çizimi tanıma.** VINS'te hiç el çizimi yok. Ayrıca araştırılacak.
- **Yazı içeriğini okuma (OCR).** Elemanlar katalogdaki varsayılan metinle gelir. `VNRecognizeTextRequest` ile metin okuma sonraki iş.
- **Aşama 2: vision-LLM ince ayarı** (screen_annotation + Qwen2-VL/LoRA). Aşama 1 bitince ayrı bir tasarımla ele alınacak.
- Slider ve TabBar tespiti. Datasette Slider hiç yok, alt gezinme ise sadece 20 örnek.
- iPad/Mac'e özel arayüz (yol haritasındaki iPhone önceliğine uygun olarak).

## Başarısızlık sayılacak durumlar (anti-hedefler)

- Model eğitim verisinde iyi, test verisinde kötü sonuç veriyorsa (ezberleme).
- Bahar adımları anlamadan kopyala-yapıştır yaptıysa. Her adımda ne yapıldığı ve neden yapıldığı açıklanmalı.
- Görsel cihazdan dışarı gönderiliyorsa.
- Uygulama büyük görsellerle bellek şişiriyorsa. Görsel modele verilmeden önce küçültülmeli ([[memory-safe-code]]).

## Kısıtlar

- Eğitim Bahar'ın Mac'inde yapılır (Apple Silicon, `device="mps"`). GPU kiralanmaz.
- Minimum iOS 17.6. Core ML + Vision bu sürümde var.
- Dataset 1,2 GB ve git'e **eklenmez**. Python ortamı ve eğitim çıktıları da eklenmez.
- Modelin kaynağı belirtilmeli: VINS datasetinin lisansı/atfı uygulamadaki Lisanslar sayfasına eklenir (`Resources/Licenses`). YOLO (Ultralytics) AGPL-3.0 lisanslı. Uygulama App Store'a çıkacaksa bunun etkisi kontrol edilmeli (bkz. açık noktalar).

## Değerlendirilen yaklaşımlar

| Yaklaşım | Artısı | Eksisi |
|---|---|---|
| A) Create ML (kodsuz) | 1 günde biter, Apple'ın kendi aracı | Arkada ne olduğu görünmez. Öğrenme ve CV hedefi zayıf kalır. |
| **B) Python + YOLO → Core ML** ✅ | Gerçek ML adımları öğrenilir. Cihaz içinde çalışır, ücretsiz, gizli. | Biraz Python gerekir, 1-2 hafta sürer. |
| C) Vision-LLM ince ayarı (LoRA) | Gerçek "LLM eğitimi" | GPU ister, telefona sığmaz, sunucu gerekir. Başlangıç için çok zor. |

**Seçilen: B.** Öğrenme ve CV hedefine en iyi bu uyuyor, mevcut mimariye de oturuyor (Vision zaten `BackgroundRemover`'da kullanılıyor). C, Aşama 2 olarak sonraya bırakıldı.

## Kararlaştırılan tasarım

### 1. Klasör yapısı

```
PaperCraft/
  ml/                       ← yeni, Python tarafı
    README.md               ← adımlar + her adımın nedeni (Türkçe)
    requirements.txt        ← ultralytics sürümü sabit
    convert_vins.py         ← XML → YOLO, train/val/test bölme
    vins.yaml               ← sınıf listesi + klasör yolları
    train.py / evaluate.py / export.py
    results.md              ← test sonuçları (CV için)
    data/ runs/ .venv/      ← git'e girmez (.gitignore)
```

### 2. Etiket eşlemesi (VINS → `ElementType`)

| VINS etiketi | PaperCraft | Not |
|---|---|---|
| TextButton | `button` | |
| EditText | `textField` | |
| Switch | `switch` | 232 örnek, zayıf olabilir |
| Text | `text` | |
| Image, BackgroundImage | `image` | |
| Icon | `symbol` | |
| Toolbar | `navigationBar` | 273 örnek, zayıf olabilir *(builder check sonrası benim kararım)* |
| UpperTaskBar | atılır | Bu aslında telefonun **durum çubuğu** (saat, pil). Uygulama çubuğu değil. Eşlenseydi her ekranın tepesine ince bir nav bar sıkışırdı. |
| Card | `box` | |
| Diğer (Drawer, Modal, Spinner, CheckBox, PageIndicator, CheckedTextView…) | atılır | az örnek ya da PaperCraft'ta karşılığı yok |

**İç içe etiketler** *(benim kararım)*: Datasette neredeyse her `EditText`'in içinde ayrı bir `Text` kutusu (placeholder) var. Bazı `TextButton`'ların içinde de `Icon` var. Bu iç kutular **dönüştürme sırasında atılır**. Böylece model yazı kutusunu ve butonu tek bir parça olarak öğrenir, uygulamada da üst üste binen fazladan bir eleman oluşmaz. "İçinde" demek, iç kutunun alanının en az %80'i dış kutunun içinde kalıyor demek.

Sınıf sırası `vins.yaml` dosyasında sabittir. Swift tarafı etiketi isimle eşler: modelin ürettiği isim doğrudan `ElementType` ham değeridir (`"button"`, `"textField"`…). Böylece ayrıca bir tablo tutmaya gerek kalmaz. Tanınmayan bir isim gelirse `.unknown` olur ve atlanır.

### 3. Veri bölme

Tüm alt klasörler (iphone, Android, Rico, uplabs, Wireframes) birleştirilir. Sonra **sabit bir seed** ile %70 / %15 / %15 olarak train / val / test bölünür. Böylece sonuç tekrarlanabilir olur.

### 4. Eğitim

`yolo11n.pt` ile başlanır (transfer learning). Ayarlar: `imgsz=640`, `epochs=50` (iyileşme durunca erken durur), `device="mps"`.

**Kamera fotoğrafları için veri çoğaltma (augmentation):** Datasetteki görseller temiz ekran görüntüleri, ama kamerayla çekilen fotoğraf eğik, bulanık ya da farklı ışıkta olabilir. Bu yüzden eğitimde YOLO'nun hazır çoğaltma ayarları açılır: hafif perspektif (`perspective`), parlaklık/renk oynaması (`hsv_v`, `hsv_s`) ve hafif bulanıklık. Böylece model kusurlu görsellere de alışır. Sınıfları yatay çevirme (`fliplr`) kapatılır, çünkü arayüzlerde sağ ve sol anlamlıdır.

**Kamera testi:** Test setine ek olarak, PaperCraft ekranlarının telefonla çekilmiş yaklaşık 20 fotoğrafı elle etiketlenir (küçük bir "gerçek hayat" seti). Sonuçlar `results.md`'ye ayrı bir satır olarak yazılır. Böylece "temiz görselde X, kamerada Y" farkı görünür.

En iyi model `runs/.../best.pt` dosyasına kaydedilir. Test sonuçları sınıf bazında `results.md`'ye yazılır.

### 5. Core ML'e çevirme

`model.export(format="coreml", nms=True)` ile `PaperCraftDetector.mlpackage` üretilir ve Xcode projesine eklenir. Bu dosya birkaç MB olduğu için git'e eklenir.

### 6. Uygulama tarafı

- **`Services/ElementDetector.swift`** (yeni, `BackgroundRemover` ile aynı kalıp): `CGImage` alır, `[CanvasElement]` döner.
  - Görsel önce küçültülür (en uzun kenar ~1024 px).
  - `VNCoreMLRequest` çalıştırılır, güveni eşiğin (≈0,4) altında kalan sonuçlar atılır.
  - Vision kutusunun orijini **sol alt** köşededir, PaperCraft'ınki sol üst. Bu yüzden y ekseni çevrilir: `y = 1 - (box.minY + box.height)`.
  - Kutu `NormalizedFrame`'e çevrilir: x ve genişlik görsel genişliğine göre, y ve yükseklik görsel yüksekliğine göre. Görsel tek bir ekran kabul edilir.
  - Her eleman `ComponentCatalog.makeElement(of:)` ile varsayılan özellikleriyle oluşturulur, sonra çerçevesi atanır.
  - Elemanlar büyükten küçüğe sıralanır. Böylece kart ve görsel altta, yazı ve buton üstte çizilir.
- **Giriş noktası** *(benim kararım, en basit yol)*: Sadece editörde, sayfalar menüsünde "Görselden sayfa ekle". Oluşan sayfa açık projeye eklenir ve ona geçilir. İki kaynak var:
  - **Fotoğraflar:** `PhotosPicker`.
  - **Kamera:** Apple'ın hazır belge tarayıcısı `VNDocumentCameraViewController` (VisionKit). Fotoğraftaki ekranın ya da kağıdın kenarlarını kendisi bulur, eğikliği düzeltir ve çevresini kırpar. Bu sayede model, eğitildiği görsellere en çok benzeyen düz bir görsel alır. Bunun için Info.plist'e kamera izni metni (`NSCameraUsageDescription`) eklenir.
  - Seçilen görsel analiz edilirken bir animasyon gösterilir. Bitince yeni bir `PrototypeScreen` oluşur. Hiç eleman bulunamazsa "Bu görselde eleman bulunamadı" mesajı ve "tekrar dene" seçeneği gösterilir.
- **Test:** `ElementDetector`'ın koordinat çevirme ve eleman oluşturma kısmı saf bir fonksiyon olarak yazılır ve birim testiyle doğrulanır (sahte gözlemlerle). Modelin kendisi simülatörde de çalışır (Core ML, Neural Engine yoksa CPU'ya düşer).

### 7. Öğretim biçimi

Her adım Bahar'la birlikte yapılır. Önce kısa bir açıklama ve kod, sonra çalıştırma, sonra çıktıyı birlikte yorumlama. `ml/README.md` her adımın "ne / neden" açıklamasını tutar.

## Uygulayıcıya bırakılanlar

- Analiz animasyonunun görünüşü, butonun tam olarak nerede duracağı.
- Güven eşiği ve görsel boyutunun ince ayarı (test sonuçlarına bakarak).
- Script'lerin iç yapısı.

## Açık noktalar

- **Ultralytics AGPL-3.0:** Kişisel ya da öğrenme projesi için sorun değil. App Store'da kapalı kaynak bir uygulamada kullanılacaksa ticari lisans ya da başka bir model gerekebilir. Yayın öncesinde karar verilecek.
- **VINS lisansı ve atıf metni:** Dataset kaynağı doğrulanıp Lisanslar sayfasına eklenecek.
