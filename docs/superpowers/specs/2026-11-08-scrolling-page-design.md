# Kayan Sayfa — Tasarım

Tarih: 8 Kasım 2026 · Durum: kullanıcı özeti onayladı ("sen bir başla, düzeltmeleri sonra yaparız")

## Neden

Popüler uygulama analizinde akış, liste ve menü ekranlarının (WhatsApp sohbetleri, Getir ana sayfa, Instagram akış, banka işlemleri) hepsi aynı yerde takıldı: sayfa 393×852'den uzun olamıyor. Kayan sayfa bu ekranların önünü açar ve sonraki iş olan **grup / bileşen**'in (bir satırı tek parça yapıp çoğaltma) çoğaltılan satırlarına yer açar.

## Kullanıcının istediği

- **Telefon kartı büyümez.** Editörde alan zaten dar; kart telefon boyunda kalır, içindeki tasarım gerçek bir uygulama gibi aşağı kayar.
- **Editörde kaydırmanın sonu yok.** Hiç eleman eklemeden de aşağı inilebilir; arka plan kesintisiz devam eder (boş kâğıt gibi).
- **Sayfanın gerçek uzunluğu**, en alttaki elemanın birkaç milim altında biter (en az telefon boyu). Sebep: kullanıcı ileride bütün ekranlara bir bütün olarak bakacak (UIKit / storyboard ekranları gibi); sayfa orada görünmeli.
- **Üst bar ve alt sekme barı** için uygulamaya göre seçim: Özellikler sayfasında **"Kaydırınca: Sabit / Sayfayla kayar"**. Varsayılan Sabit.

## Hedefler

1. Editörde dikey kaydırma (tek parmak, boş yerde sürükleyerek).
2. Elemanlar ilk ekranın altına konabilir, taşınabilir, boyutlandırılabilir.
3. Dene'de sayfa gerçek uzunluğunda kayar; sabit barlar yerinde kalır.
4. Sayfalar ızgarasında uzun sayfanın kartı uzun görünür.
5. Üst bar / alt menüde "Kaydırınca" seçeneği.
6. Mevcut hata: Özellikler sayfası açılınca canvas seçili eleman için yukarı kayıyor ve saydam üst barın arkasında yazılar üst üste görünüyor. Kaydırma gelince canvas'ı kaldırmak yerine içeriği kaydırarak çözülür.

## Hedef değil

- Grup / bileşen (sonraki iş).
- Yatay kayan şeritler, sayfa içinde ayrı kayan bölgeler.
- Kaydırınca küçülen büyük başlık.
- Sayfa uzunluğunu elle girme.

## Başarısızlık sayılır (çalışsa bile)

- Eski projelerin elemanlarının yeri değişirse.
- Kısa (tek ekranlık) sayfalar editörde ya da Dene'de eskisinden farklı görünürse.
- Kaydırma, eleman seçme/taşıma/boyutlandırma ya da yakınlaştırma ile çakışıp onları zorlaştırırsa.

## Nasıl (kararlar)

### Koordinatlar — *benim kararım*
`NormalizedFrame` aynı kalır: `x`, `width` ekran genişliğine; `y`, `height` **ekran yüksekliğine (852)** göre. Fark: `y` artık 1'i geçebilir (`y = 1.5` → ikinci ekranın ortası). Eski kayıtların hepsi 0…1 aralığında olduğu için hiçbir şey değişmez; şema sürümü artırılmaz.

### Sayfanın gerçek uzunluğu
`PrototypeScreen.contentHeight` (ekran yüksekliği birimiyle) = `max(1, en alttaki serbest elemanın alt kenarı + 24 pt)`. Sabit barlar hesaba katılmaz. Dene, ızgara kartı ve arka planın geçişi bunu kullanır.

### Sabit / kayan barlar
- Yeni enum `ScrollBehavior { fixed, scrolls }` ("Sabit", "Sayfayla kayar"), alan `scrollBehavior`; üst bar ve alt menü kullanır, varsayılan `fixed`.
- Sabit bar: `y`'si ekranın görünen kısmına göredir (0…1), içerik kayarken yerinde durur, içerik altından geçer.
- Kayan bar: diğer elemanlar gibi sayfanın içinde durur. *Benim kararım:* alt menü "kayar" seçilince de bulunduğu yerde (sayfa içinde) kalır; ayrıca sayfa sonuna taşınmaz.

### Editör
- `CanvasView`'a `scrollOffset` (tuval point'i) eklenir; elemanlar ve arka plan bu kadar yukarı çizilir, sabit barlar çizilmez kaymaz.
- **Hareket:** boş yerde tek parmakla sürüklemek dikey kaydırır. Yakınlaştırılmışken önce kart kendi sınırına kadar kayar (bugünkü gibi), artan dikey hareket sayfayı kaydırır. Elemanın üstünde sürüklemek her zaman elemanı taşır.
- **Sınır:** üstte 0; altta `contentHeight`'in bir ekran fazlası (her zaman bir boş ekran daha) — "sonsuz" hissi verir, boşlukta kaybolmayı önler. *Benim kararım.*
- **Sayfa sonu çizgisi:** `contentHeight`'te kesik çizgi + küçük "Sayfa sonu" etiketi; gerçek uzunluk editörde görünür. *Benim kararım.*
- **Ekleme:** katalogdan eklenen serbest eleman, o an görünen alanın ortasına gelir. Barlar eskisi gibi en üste / en alta.
- **Taşıma ve boyut:** serbest elemanlarda alttaki sınır kalkar (üstte 0, yanlarda ekran genişliği). Sabit barlar 0…1 içinde kalır. Çoğaltma da alttan kırpılmaz.
- **Kenarda otomatik kaydırma:** eleman sürüklenirken parmak kartın alt/üst kenarına yaklaşınca sayfa o yöne kayar. Planın son adımı; zor çıkarsa ayrı iş olarak ertelenebilir.
- **Özellikler sayfası açılınca:** seçili eleman sayfanın altında kalacaksa kart kaldırılmaz, içerik kaydırılır (hatayı düzeltir).

### Arka plan
Geçiş, sayfanın gerçek uzunluğu boyunca yayılır. Editörde onun altına inilirse son renkle devam eder. *Kullanıcı tahmini onayladı (özette vardı).*

### Dene
- Sayfa tek ekranlıksa (`contentHeight == 1`) bugünkü yerleşim aynen kalır.
- Uzunsa: içerik `ScrollView` içinde, genişliğe göre ölçeklenmiş, `y × 852 × ölçek` konumunda; sabit üst bar güvenli alanın altında, sabit alt menü en altta durur.
- Aşağı çekip kapatma yalnızca sayfa en üstteyken çalışır.

### Sayfalar ızgarası
Kart sayfanın gerçek oranında uzar. *Benim kararım:* en fazla 2 ekran boyu gösterilir, altı soluklaşarak kesilir.

## Builder'a kalanlar
Kod yapısı, dosya bölünmesi, animasyon süreleri, çizgi/etiket görünümü, otomatik kaydırma hızı.

## Test
- Model: `contentHeight` (boş sayfa, kısa sayfa, uzun sayfa, sabit barın sayılmaması), `scrollBehavior` varsayılanı ve bilinmeyen değer.
- ViewModel: görünen alana ekleme, alttan sınırsız taşıma/boyut, sabit barın 0…1'de kalması, çoğaltma.
- Kaydırma sınırları ve yakınlaştırma ile birleşen sürükleme hesabı (`CanvasViewport` benzeri saf tip).
- Dene yerleşimi: kısa sayfada eski konumlar aynen, uzun sayfada kayan konumlar.
- Simülatör: `-openEditor` ile kaydırma, ekleme, Dene'de kaydırma ve sabit bar.
