# ml/ — Arayüz elemanı dedektörü

VINS veri setiyle bir YOLO modeli eğitiyoruz. Model, ekran görüntüsündeki butonları, metinleri vb. bulacak.

## 1. Kurulum

**Ne yapıyoruz:** `ml/` içinde ayrı bir Python ortamı (venv) kuruyoruz.
**Neden:** Sistem Python'u 3.9, ultralytics için eski. Ayrı ortam projeyi temiz tutar. `uv` hızlı bir kurulum aracı.

```bash
uv venv --python 3.12 ml/.venv
uv pip install --python ml/.venv/bin/python -r ml/requirements.txt
ml/.venv/bin/python -m pytest -q ml     # testler
```

## 2. Etiket eşlemesi

**Ne yapıyoruz:** VINS'in etiketlerini bizim 8 sınıfa çeviriyoruz. Gerisini atıyoruz.
**Neden:** Uygulamamızda sadece bu 8 eleman var. Durum çubuğu (`UpperTaskBar`) gibi etiketler öğretmenin işine yaramaz.

| VINS | Bizim sınıf |
|---|---|
| Text | text |
| TextButton | button |
| EditText | textField |
| Image, BackgroundImage | image |
| Icon | symbol |
| Card | box |
| Toolbar | navigationBar |
| Switch | switch |

Ek kural: bir `textField` içinde %80'den fazla duran `text` (placeholder) ve bir `button` içindeki `symbol` atılır. Çünkü bunlar ayrı eleman değil, elemanın parçası.

```python
drop_nested([("textField",0,0,100,40), ("text",5,5,60,35)])  # -> sadece textField
```

## 3. Veriyi bölme (train / val / test)

**Ne yapıyoruz:** Resimleri %70 / %15 / %15 olarak üçe bölüyoruz (seed 42).
**Neden:** Model `train` ile öğrenir, `val` ile kendini ayarlar, `test` ile en sonda dürüstçe ölçülür. Seed sabit, böylece her çalıştırmada aynı bölme çıkar.

```bash
cd ml
.venv/bin/python convert_vins.py "$HOME/Downloads/All Dataset" data/
```

Çıktı `ml/data/{train,val,test}/{images,labels}/` altına yazılır (git'e girmez). Resimler kopyalanmaz, **symlink** olarak bağlanır: disk tasarrufu. Orijinal veri setine dokunulmaz.

## 4. Eğitim ve metrikler

**Ne yapıyoruz:** `yolo11n` modelini VINS ekran görüntüleriyle eğitiyoruz, sonra test setinde ölçüyoruz.
**Neden:** Sıfırdan başlamak yerine **transfer learning** kullanıyoruz: `yolo11n.pt` zaten milyonlarca resimde "kenar, şekil, nesne" görmeyi öğrenmiş. Biz ona sadece "bu 8 arayüz elemanı şuna benzer" diyoruz. Daha az veri ve zamanla iyi sonuç verir.

```bash
cd ml
.venv/bin/python train.py            # tam eğitim, saatler sürer
.venv/bin/python train.py --smoke    # 1 dakikalık deneme
.venv/bin/python evaluate.py runs/detect/vins/weights/best.pt --split test
```

Çıktı `ml/runs/detect/vins/` altına yazılır (git'e girmez). `weights/best.pt` en iyi modeldir.

### Eğitim ayarları

| Argüman | Anlamı |
|---|---|
| `epochs=50` | Veri setini en fazla 50 kez baştan sona görür |
| `patience=10` | 10 epoch boyunca val skoru artmazsa erken durur (ezberlemeyi engeller) |
| `imgsz=640` | Resimler 640 piksele ölçeklenir |
| `device="mps"` | Mac'in GPU'sunu kullanır (CPU'dan çok hızlı) |
| `fliplr=0.0` | Yatay çevirme kapalı: arayüzler sağ-sol simetrik değil, çevirirsek yanlış öğrenir |
| `perspective=0.0005` | Çok hafif perspektif bozulması (ekran görüntüsü biraz eğri çekilmiş gibi) |
| `hsv_v=0.4` | Parlaklık değişimi (açık/koyu tema) |
| `hsv_s=0.5` | Renk canlılığı değişimi |
| `degrees=2` | En fazla 2 derece döndürme |

Son beşi **augmentation**: aynı resmi küçük değişikliklerle göstererek modelin ezberlemesini önler.

### Metrikleri okumak

- **Precision:** "Bulduğum kutuların kaçı doğru?" Düşükse model fazla yanlış alarm veriyor.
- **Recall:** "Gerçek elemanların kaçını buldum?" Düşükse model eleman kaçırıyor.
- **mAP50:** Kutu gerçek kutuyla en az %50 örtüşürse doğru sayılır. Genel kalite skoru, 1'e yakın iyi.
- **mAP50-95:** Aynısı ama %50'den %95'e kadar sıkı eşiklerle. Kutunun ne kadar **hassas** oturduğunu ölçer, hep mAP50'den düşüktür.

```
text  precision 0.80  recall 0.75  mAP50 0.78  mAP50-95 0.55   # örnek satır
```
