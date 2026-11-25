# Sonuçlar

## Eğitim 1 — 2026-11-25

- **Model:** YOLO11n (transfer learning), `runs/detect/vins/weights/best.pt`
- **Veri:** VINS, 4.807 görsel → eğitim 3.364 / kontrol 721 / sınav 722 (seed 42)
- **Ayarlar:** 50 tur (erken durmadı), `imgsz=640`, `device=mps` (Apple M2), yaklaşık 3,5 saat
- **Çoğaltma:** `fliplr=0`, `perspective=0.0005`, `hsv_v=0.4`, `hsv_s=0.5`, `degrees=2`

### Sınav seti (722 görsel, model hiç görmedi)

| sınıf | örnek | precision | recall | mAP50 | mAP50-95 |
|---|---|---|---|---|---|
| text | 4415 | 0.926 | 0.953 | 0.966 | 0.847 |
| button | 731 | 0.953 | 0.988 | 0.989 | 0.973 |
| textField | 363 | 0.964 | 0.931 | 0.977 | 0.868 |
| image | 1458 | 0.854 | 0.870 | 0.929 | 0.872 |
| symbol | 1905 | 0.895 | 0.909 | 0.946 | 0.803 |
| box | 38 | 1.000 | 0.417 | 0.668 | 0.602 |
| navigationBar | 36 | 0.612 | 0.833 | 0.808 | 0.776 |
| switch | 35 | 0.967 | 0.848 | 0.983 | 0.920 |
| **tümü** | | **0.896** | **0.844** | **0.908** | **0.833** |

### Yorum

- Bol örnekli sınıflar (text, button, textField) çok iyi: mAP50 0.97 ve üstü.
- **box zayıf:** Model bulduğu kutularda hiç yanılmıyor (precision 1.0) ama gerçek kartların yarısından fazlasını kaçırıyor (recall 0.42). Sebebi eğitimde sadece 168 örnek olması.
- **navigationBar orta:** Çoğunu buluyor (recall 0.83) ama sık sık yanlış yere de nav bar diyor (precision 0.61).
- **switch beklenenden iyi:** 232 örneğe rağmen 0.98. Switch'in şekli çok belirgin olduğu için kolay öğrenildi.
- Sınavdaki az örnekli sınıflarda yaklaşık 35 örnek var, bu yüzden o sayılar biraz oynak olabilir.

### CV için tek satır

> Trained a YOLO11n object detector on 4.8k UI screenshots (VINS) to recognise 8 UI element types; 0.91 mAP50 / 0.83 mAP50-95 on a held-out test set, exported to Core ML for on-device inference.
