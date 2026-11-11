# Hizalama Kılavuzları ve Yapışma — Tasarım

Tarih: 11 Kasım 2026 · Durum: taslak, kullanıcı onayı bekliyor

> **Güncel karar (11 Kasım 2026, denedikten sonra):** Her kenara hizalamak ekranı çizgiyle doldurdu. Kullanıcı yalnızca iki hiza istiyor: **sayfanın dikey ortası** (elemanın ortası) ve **diğer elemanın sol kenarı** (sol–sol). Orta–orta, sağ–sağ ve bütün yatay hizalar (üst, orta, alt) kaldırıldı. Aşağıdaki diğer hizalar, karşı kenarlar ve boyutlandırma bölümleri şimdilik geçersizdir; gerekirse kullanıcıya yeniden sorulur.

## Neden

Elemanları şu an göz kararı hizalıyoruz. Telefonda parmakla tam noktayı tutturmak zor. Ayarlar ekranı gibi satır satır dizilen tasarımlarda bu en çok zaman alan iş. Kullanıcı Figma'daki gibi bir şey istiyor: sürüklerken hizaya gelince beliren ince renkli çizgiler.

## Kullanıcının istediği

- Eleman sayfanın **tam ortasına** gelince dikey bir orta çizgisi çıkar.
- Başka bir elemanın **üst kenarıyla** aynı hizaya gelince yatay bir çizgi çıkar.
- Başka bir elemanın **sol ya da sağ kenarıyla** aynı hizaya gelince dikey bir çizgi çıkar.
- Benim önerdiğim ve kullanıcının onayladığı ekler:
  - Eleman hizaya **hafifçe yapışır**. Biraz daha çekince kurtulur.
  - Üst kenara ek olarak **alt kenar** ve **orta** (iki merkez aynı hizada) da sayılır.
  - Yapışınca telefon **hafifçe titrer**.
  - Çizgiler yalnızca parmak ekrandayken görünür. Dene modunda hiç çıkmaz.
  - Köşeden **boyutlandırırken** de çalışır.

## Hedefler

1. **Taşırken:** Taşınan elemanın sol / orta / sağ kenarı, diğer elemanların sol / orta / sağ kenarına ya da sayfanın dikey ortasına yapışır. Üst / orta / alt kenarı da diğer elemanların üst / orta / alt kenarına yapışır. Yatay ve dikey yapışma birbirinden bağımsızdır, ikisi aynı anda olabilir.
2. **Boyutlandırırken:** Yalnızca çekilen köşenin iki kenarı, diğer elemanların aynı eksendeki kenarlarına (sol, orta, sağ / üst, orta, alt) ve sayfanın ortasına yapışır. Karşı köşe yine yerinde kalır.
3. Hizalanan her eksen için bir çizgi çizilir.
4. Yeni bir hizaya yapışıldığı anda bir kez titreşim olur. Aynı hizada dururken tekrar titremez.
5. **Karşı kenarlar (kullanıcının kararı):** Bir elemanın üst kenarı diğerinin alt kenarına (ya da sol kenarı diğerinin sağına, vb.) yalnızca iki eleman **birbirine değince** yapışır: hareket eden eleman diğerinin üstüne eşik kadar ya da daha az binmişse geri itilip bitişik oturur. Arada boşluk varken çekmez; böylece bilerek bırakılan 2–3 noktalık boşluk korunur. Eşikten fazla binerse yapışmaz (kartın üstüne yazı koymak gibi bilerek üst üste koyma).
6. Geri al davranışı değişmez: bir taşıma ya da boyutlandırma yine tek adımdır ve yapışılmış son konum kaydedilir.

## Hedef değil

- Katalogdan sürükleyip bırakırken yapışma.
- Eşit aralık kılavuzları (Figma'nın "aradaki boşluklar eşit" gösterimi).
- Sayfa kenarlarına ya da kenar boşluklarına yapışma (yalnızca sayfa ortası var).
- Sayfanın yatay ortası (sayfa kaydığı için anlamı belirsiz).
- Yapışmayı kapatma ayarı ya da geçici kapatan bir tuş.
- Özellikler sayfasından sayıyla girilen konum ve boyut.
- Çoklu seçim.

## Olmaması gerekenler

- Elemanı istenen yere koymayı zorlaştırmamalı. Yapışma eşiği küçük olmalı; kullanıcı iki elemanı bilerek 3 nokta aralıklı koyabilmeli (biraz yakınlaştırarak).
- Ekran çizgilerle dolmamalı. Bir eksende yalnızca en yakın hizanın çizgisi çıkar.
- Sürükleme takılmamalı. 30–40 elemanlı bir sayfada akıcı kalmalı.

## Nasıl çalışır (kararlaştırılanlar)

### Hesap

- Hesap, referans ekranın **point** biriminde yapılır (393 genişlik). `EditorViewModel.pointRect(of:)` bu dönüşümü zaten yapıyor.
- Yapışma hesabı arayüzden bağımsız, saf bir türde durur (örneğin `SnapGuides`, `ViewModels/` altında). Girdi: hareket eden elemanın ham (parmağın getirdiği) dikdörtgeni, hangi kenarları hareket ediyor, diğer elemanların dikdörtgenleri, eşik. Çıktı: düzeltme miktarı (dx, dy) ve çizilecek çizgiler. Böylece birim testle sınanabilir.
- Yapışma her karede **ham konumdan** yeniden hesaplanır, önceki yapışılmış konumdan değil. Böylece "biraz daha çekince kurtulma" kendiliğinden olur: ham konum eşiğin dışına çıkınca düzeltme sıfırlanır.
- **Eşik ekranda sabit 6 point**'tir. Yakınlaştırılmışken eşik `6 / scale` olur, yani yakınlaştırınca daha hassas yerleştirme yapılabilir.
- Bir eksende eşik içinde birden çok hiza varsa **en yakını** seçilir. Eşitlikte ilk bulunan yeter.

### Hangi elemanlar hedef olur

- Hareket eden elemanın kendisi hariç bütün elemanlar.
- Ekran kenarına (x = 0 ya da 393) denk gelen kenarlar hedef sayılmaz; tam genişlikteki üst bar / alt menü yanlarda "ekran kenarına yapışma" yaratmasın (benim kararım).
- **Yatay hizalar (x):** bütün elemanlar, sabit ya da kayan fark etmez (x iki katmanda da aynı).
- **Dikey hizalar (y):** yalnızca **aynı katmandaki** elemanlar. Sabit üst bar / alt menünün y'si ekrana, diğerlerinin y'si sayfaya göredir; karıştırılırsa sayfa kaydırılmışken yanlış hizalar çıkar.
- Döndürülmüş elemanlarda (görsel, sembol; açılar 90°'nin katı) elemanın **ekranda kapladığı kutu** kullanılır: 90° ve 270°'de genişlik ile yükseklik yer değiştirir, merkez aynı kalır.

### Taşırken

- `CanvasView.dragGesture` her `onChanged`'de ham kaymayı (`dragOffset` + kenarda kendiliğinden kayılan `edgeScrolled`) bulur, yapışma düzeltmesini ekler ve görüntüyü düzeltilmiş konumda gösterir.
- `onEnded`'de `moveElement`'e düzeltilmiş kayma gönderilir. `moveElement`'in sayfa sınırlarına sıkıştırması aynen kalır.

### Boyutlandırırken

- Şu an `resizeElement` parmağın **son karedeki** küçük hareketini alıyor. Ham konumdan yeniden hesaplayabilmek için boyutlandırma başlarken elemanın ilk dikdörtgeni saklanır ve her karede `ilk dikdörtgen + toplam parmak hareketi` üzerinden yeni dikdörtgen bulunup yapışma uygulanır. Bunun nasıl kurulacağı (ViewModel'de "boyutlandırma başladı/bitti" çağrıları ya da toplam hareketi gönderen yeni bir fonksiyon) yapıcıya kalmıştır.
- En küçük boyut, sayfa sınırları ve daire butonun kare kalması kuralları yapışmadan **sonra** uygulanır; yani gerekirse yapışmayı bozarlar.
- **Döndürülmüş** (açısı 0 olmayan) elemanı boyutlandırırken yapışma yapılmaz. Karşı köşeyi yerinde tutan hesap zaten karmaşık; buna değmez.

### Çizgiler

- Çizgiler canvas kartının içinde, elemanların üstünde, dokunuşu almayan bir katmanda çizilir.
- **Eleman–eleman hizası:** çizgi, iki elemanı birlikte kapsayacak uzunlukta çizilir (Figma gibi). Örneğin iki elemanın sol kenarı hizalıysa dikey çizgi, üstteki elemanın tepesinden alttakinin dibine uzanır.
- **Sayfa ortası:** dikey çizgi kartın görünen yüksekliği boyunca çizilir.
- Kalınlık ekranda 1 point (`1 / scale`). Renk: seçim çerçevesinin mavisinden ve `Theme.accent`'ten ayrışan canlı bir pembe/eflatun. `Theme`'e `snapGuide` adıyla eklenir.

### Titreşim

- `.sensoryFeedback(.alignment, trigger:)` kullanılır (iOS 17 / macOS 14'te var). Tetikleyici, o an yapışılmış hizaların kimliğidir; yeni bir hizaya geçince değişir, kurtulunca titremez.

## Test

- `SnapGuides` için birim testleri: eşik içi/dışı, en yakın hizayı seçme, x ve y'nin ayrı yapışması, sayfa ortası, sabit/kayan katman ayrımı, döndürülmüş kutu, yakınlaştırmada eşiğin küçülmesi, boyutlandırmada yalnızca hareket eden kenarların yapışması.
- Simülatörde: iki butonu sol kenardan hizalama, bir yazıyı ortaya alma, sol kenarları hizalı iki elemanda köşeden çekip sağ kenarı da hizalamak. (Boyut eşitleme — "aynı genişlik" yapışması — yok; yalnızca kenarlar hizalanır. Benim kararım.)

## Sıra

Kullanıcı önce tek çizgi istedi: ilk adım yalnızca **taşırken sayfa ortası**. Sonra eleman–eleman hizaları, karşı kenarlar ve boyutlandırma.

## Yapıcıya kalanlar

- Türlerin ve dosyaların adları, hesabın nerede çağrılacağı (View içinde ya da ViewModel'de).
- Çizgi katmanının hangi View'da duracağı.
- 30–40 elemanda performans sorun olursa basit bir ön eleme (ör. hedef listesini sürükleme başında bir kez hazırlamak).
