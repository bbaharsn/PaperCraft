# Toplu Seçim ve Kutunun Kap Olması — Tasarım

Tarih: 11 Kasım 2026 · Durum: taslak, kullanıcı onayı bekliyor

## Neden

Şu an bir seferde yalnızca tek bir eleman taşınabiliyor. Ayarlar ekranındaki gibi Kutu + Sembol + Yazı'dan oluşan bir satırı kaydırmak için üç elemanı tek tek taşımak gerekiyor ve aradaki hizalar bozuluyor. Kullanıcı Figma'dakine benzer bir davranış istiyor: birkaç eleman birlikte seçilsin ve birlikte kaysın, kutunun içine konan elemanlar da kutuyla birlikte hareket etsin.

## Kullanıcının istediği

- Üst barda **ayrı bir düğme** olarak bir toplu seçim modu.
- Bir **Kutu**, Figma'daki frame gibi bir kap olsun. İçine konan elemanlar kutuyla ortak sayılsın ve kutu sürüklenince onunla birlikte gelsin.
- Sürüklerken birlikte hareket eden bütün elemanların etrafında Figma'daki gibi **kesikli çizgiler** görünsün.
- Önce yapılsın, beğenilmeyen yerler sonra değiştirilsin.

## Hedefler

### 1. Toplu seçim modu

1. `EditorTopBar`'a, katalog düğmesinin yanına yeni bir düğme eklenir (ikon önerisi: `checklist` ya da `square.on.square.dashed`). Mod açıkken düğme dolu görünür (zemin `Theme.ink`, ikon `Theme.paper`).
2. Mod açıkken bir elemana **dokunmak**, onu seçime ekler. Seçili bir elemana dokunmak onu seçimden çıkarır.
3. Seçili her elemanın etrafında **kesikli bir çerçeve** çizilir. Ayrıca bütün seçili elemanları saran **tek bir ortak çerçeve** de çizilir (ince, düz çizgi). Bu modda köşe tutamaçları ve döndürme tutamacı gösterilmez.
4. Seçili elemanlardan **herhangi biri sürüklenince hepsi birlikte kayar**. Sürükleme sırasında da kesikli çerçeveler görünür.
5. Hizalama çizgileri (snap) **ortak çerçeveye** göre çalışır. Hedef olarak yalnızca seçimde olmayan elemanlar kullanılır.
6. Bütün taşıma **tek bir geri al adımı** olur.
7. Alttaki `SelectionToolbar` en az bir eleman seçiliyken görünür. **Sil** düğmesi seçili elemanların hepsini siler. Toplu modda **Çoğalt** gösterilmez.
8. Mod açıkken boş bir yere dokunmak seçimi temizler ama modu kapatmaz.
9. Düğmeye tekrar basınca mod kapanır ve seçim temizlenir.
10. Mod açıkken **çift dokunma** ve **uzun basma** Özellikler sayfasını açmaz. Mod açılınca açık olan Özellikler, Arka Plan ve katalog sayfaları kapanır.
11. Mod açıkken tek bir seçili eleman sürüklenirse, o eleman tek başına taşınır (Kutu ise içindekiler de kurala göre gelir, bkz. 2).
12. *(Benim kararım)* Mod açıkken **seçili olmayan** bir eleman sürüklenirse yalnızca o eleman taşınır (Kutu ise içindekilerle). Seçim değişmez.
13. *(Benim kararım)* Mod açıkken katalog düğmesine basılırsa mod kapanır ve seçim temizlenir. Böylece yeni eklenen eleman normal tek seçimle seçilir.

### 2. Kutu bir kap olur

1. Sürükleme başladığında, sınırları **tamamen** bir Kutu'nun (`ElementType.box`) içinde kalan ve dizide o kutudan **sonra gelen** (yani üstte çizilen) elemanlar o kutunun **içindekiler** sayılır. Bu bağ modele kaydedilmez, her sürüklemede konumlardan yeniden hesaplanır. Böylece kutudan dışarı çıkarılan bir eleman kendiliğinden ayrılır, kutunun içine bırakılan eleman kendiliğinden katılır.
2. İç içe kutular: içteki kutu ve onun içindekiler de dışarıdaki kutuyla birlikte gelir. Hesap özyinelemelidir ya da doğrudan "dış kutunun içinde kalan her şey" diye yapılır; ikisi aynı sonucu verir.
3. Kutu sürüklenince kutu ve içindekiler birlikte kayar. Hepsinin etrafında kesikli çerçeveler görünür, hizalama ortak çerçeveye göre çalışır, taşıma tek geri al adımıdır.
4. Kutunun içindeki bir eleman sürüklenince yalnızca o eleman (içinde kutu ise onun içindekilerle) taşınır.
5. Kutuyu **boyutlandırmak** içindekileri etkilemez.
6. Toplu seçim modunda seçime bir Kutu eklendiyse, o kutunun içindekiler de taşımaya katılır (seçilmemiş olsalar bile).
7. **Silme (kullanıcının kararı):** Bir Kutu silinince içindekiler de silinir (Figma'daki gibi). Bu hem normal modda tek silmede hem toplu modda geçerlidir. İçindekiler, taşımadaki aynı kuralla (2.1) bulunur. Silme tek bir geri al adımıdır; geri alınca kutu ve içindekiler eski sıralarıyla geri gelir.
8. Döndürülmüş elemanlar için "içinde mi" hesabı döndürülmüş halin kapladığı kutuyla (`SnapGuides.boundingBox`) yapılır. Kutunun kendisi döndürülemez.

### 3. Çizim sırası (önemli tuzak)

`EditorViewModel.select(_:)` seçilen elemanı dizinin sonuna taşıyarak en üste çıkarıyor. Bir Kutu seçilince içindekilerin üstüne çıkar ve onları örter, üstelik 2.1'deki "kutudan sonra gelen" kuralına göre içindekiler artık sayılmaz. Bu yüzden:

- Bir Kutu öne getirilirken, **içindekiler de** (kendi aralarındaki sırayı koruyarak) kutunun hemen arkasından en üste taşınır.
- Toplu seçim modunda dokunmak hiçbir elemanın sırasını değiştirmez.
- Sıra değişimi şu anki gibi geri al adımı sayılmaz.
- *(Benim kararım)* Toplu modda bir grup **sürüklendiğinde**, taşınan bütün elemanlar (kendi aralarındaki sırayı koruyarak) en üste çıkarılır. Böylece grup başka elemanların altına kaymaz ve bir kutunun içine bırakılan eleman o kutudan sonra gelir.
- *(Bilinen sınır, şimdilik kabul)* Bir Kutu, sayfada zaten duran elemanların üstüne sürüklenirse kutu üstte kalır ve o elemanları örter. O elemanlar kutuya katılmaz. Bir elemanı kutunun içine sürüklemek ise çalışır. Gerekirse sonra bırakınca sırayı yeniden düzenleriz.

### 4. Taşımanın sınırları

Şu an `moveElement` her elemanı ayrı ayrı sayfa kenarlarına sıkıştırıyor. Grup bu şekilde taşınırsa kenara dayanan eleman durur, diğerleri devam eder ve aradaki boşluk bozulur. Bunun yerine grup **tek parça** sınırlanır: `dx` ve `dy`, ortak çerçeve sayfanın solundan, sağından ve üstünden taşmayacak şekilde kısılır, sonra aynı miktar her elemana uygulanır. Aşağıda sayfa şu anki gibi uzar.

Sabit üst bar ve alt menü (`isPinned`) hiçbir gruba girmez: kutunun içinde görünseler bile içindekiler sayılmaz, toplu modda dokununca seçime eklenmezler.

## Hedef değil (sonraya)

- Toplu boyut değiştirme (ortak çerçeveden ölçekleme).
- Toplu özellik düzenleme ("Karışık" gösterimi).
- Hizalama ve eşit aralık araçları, gruplama (Cmd+G).
- Seçim kutusu (boş alandan sürükleyerek seçme).
- Toplu çoğaltma.
- Shift + tıklama, Cmd + A, Esc gibi klavye kısayolları (önce mobil).
- Kutu dışındaki elemanların (ör. Görsel) kap olması.

## Kısıtlar

- iPhone öncelikli. Dokunuşlar mevcut hareketlerle (çift dokunma, uzun basma, iki parmakla yakınlaştırma, boş alanda kaydırma, kenarda otomatik kaydırma) çakışmamalı.
- Bu iş, henüz commit edilmemiş hizalama çizgisi (snap) çalışmasının üstüne kurulur.
- Her yeni tür kendi dosyasında olur.
- Sürükleme sırasında model değişmez, yalnızca görüntü kayar (mevcut yaklaşım). Model bırakınca tek seferde güncellenir.
- Testler: içindekileri bulma, grup sınırlama, çizim sırası, toplu silme ve geri al için birim testleri.

## Uygulayana bırakılanlar

- Seçim durumunun modeli (ör. `selectedElementIDs: Set<UUID>` ve `isMultiSelecting`). Mevcut `selectedElementID` kullanan Özellikler sayfası gibi yerler bozulmamalı.
- "İçindekileri bulma" ve "grup sınırlama" mantığının hangi dosyalarda duracağı.
- Kesikli çizginin kalınlığı ve deseni (ekranda yakınlaştırmadan bağımsız sabit kalınlık, mevcut `SelectionOverlay` ile uyumlu renk).
- Düğmenin ikonu ve erişilebilirlik etiketi ("Toplu seçim").
