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
