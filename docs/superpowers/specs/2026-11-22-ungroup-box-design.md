# Kutuyu çöz — kısa tasarım

Tarih: 2026-11-22 · Üst tasarım: `2026-11-11-multi-select-design.md` ("Hedef değil" listesindeki "kutudan çıkarma")

## Neden
Kutunun içindekiler konumdan hesaplanıyor. Bir elemanı dışarı sürüklemek onu kutudan çıkarıyor, ama kutuyu silmek içindekileri de siliyor. "Kutuyu kaldır, içindekiler kalsın" diyecek bir yol yok. "Kutuya al" komutunun tersi eksik.

## Hedef
- Tek bir kutu seçiliyken, içinde en az bir eleman varsa, alt araç çubuğunda **"Kutuyu çöz"** düğmesi görünür: `[Kutuyu çöz] [Çoğalt] [Sil]`.
- Düğmeye basınca yalnızca kutu silinir. İçindekiler yerinde ve aynı sırada kalır. Bu tek geri al adımıdır.
- Ardından toplu mod açılır ve içindekiler seçili gelir. Böylece hemen taşınabilir ya da yeniden "Kutuya al" yapılabilir.
- İç içe kutularda yalnızca seçili kutu çözülür. İçteki kutu ve onun içindekiler olduğu gibi kalır (hepsi seçime girer).

## Hedef değil
- Toplu modda "Kutuyu çöz" yok: birden fazla kutu seçiliyken hangisinin çözüleceği belirsiz.
- İçi boş kutuda düğme yok (orada "Sil" aynı işi görür).

## Yaklaşımlar
1. **Seçilen:** kutuyu dizi içinden çıkar, içindekileri `movingGroup(for:)` ile bul ve toplu seçime ver. Mevcut "içindekiler konumdan hesaplanır" kuralıyla uyumlu, kaydedilecek yeni bir alan yok.
2. Elemana kalıcı bir "kutuya ait değil" bayrağı eklemek: içindekiler kaydedilmediği için anlamsız. Reddedildi.

## Uygulayıcıya kalan
- Düğmenin ikonu (öneri: `square.dashed` üstü çizili; `rectangle.dashed` yoksa uygun bir SF Symbol).
- `EditorViewModel+Group.swift` içinde `ungroupSelectedBox()` ve `canUngroupSelected` adlandırmaları.
