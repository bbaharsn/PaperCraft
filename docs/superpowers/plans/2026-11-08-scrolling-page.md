# Kayan Sayfa Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sayfa telefon boyundan uzun olabilsin; editörde ve Dene'de dikey kaysın, üst bar / alt menü sabit ya da kayan seçilebilsin.

**Architecture:** `NormalizedFrame.y` ekran yüksekliği birimiyle kalır ama 1'i geçebilir; sayfanın gerçek uzunluğu `PrototypeScreen.contentHeight`'ten gelir. Editör kaydırması `CanvasViewport`'a eklenen `scroll` değeriyle (saf, test edilebilir) yapılır; sabit barlar ayrı bir katmanda kaymadan çizilir. Dene uzun sayfada `ScrollView` kullanır, kısa sayfada bugünkü yerleşimi korur.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing (iOS + macOS hedefleri).

**Spec:** `docs/superpowers/specs/2026-11-08-scrolling-page-design.md`

## Global Constraints

- Eski kayıtlar değişmez; şema sürümü artırılmaz. `y` 0…1 olan elemanlar aynı yerde çizilir.
- Tek ekranlık sayfalar editörde ve Dene'de bugünkü gibi görünür.
- Referans ekran 393×852 pt (`CanvasView.referenceSize`).
- Sayfa sonu payı: en alttaki serbest elemanın altına **24 pt**.
- Editör kaydırma sınırı: `0 … (contentHeight + 1) × 852 − 852` tuval point'i (her zaman bir boş ekran daha).
- Izgara kartı en fazla **2 ekran** boyu; fazlası soluklaşarak kesilir.
- "Kaydırınca" seçenekleri: `Sabit` (`fixed`, varsayılan) / `Sayfayla kayar` (`scrolls`).
- Her dosyada tek tip; modeller `nonisolated`; bilinmeyen enum değeri varsayılana düşer; Türkçe doc yorumları.
- Commit mesajları İngilizce, maddeli; kullanıcı onayı olmadan push yok.

## Review Focus

- Uzun sayfadayken Özellikler sayfası açılır, seçili eleman görünmeli ve kart üst barın arkasına kaymamalı → Task 4 simülatör adımı.
- Eleman ikinci ekrandayken geri al / yinele aynı yere döndürmeli → Task 2 testi `undoRestoresElementBelowFirstScreen`.
- Kısa sayfa Dene'de piksel piksel eskisi gibi kalmalı → Task 6 testi `shortPageUsesStretchedLayout`.
- Sabit alt menü uzun sayfada içerik kaydıkça ekranın altında kalmalı, taşınırken 0…1 dışına çıkmamalı → Task 2 testi `pinnedBarStaysInsideViewport`.
- Yakınlaştırılmış + kaydırılmış haldeyken boş yerde sürükleme önce kartı, sonra sayfayı kaydırmalı → Task 3 testi `zoomedDragPansThenScrolls`.

---

### Task 1: Model — `ScrollBehavior`, `contentHeight`, sabit bar tanımı

**Files:**
- Create: `PaperCraft/Models/ScrollBehavior.swift`
- Modify: `PaperCraft/Models/ElementProperties.swift` (Üst bar bölümü), `PaperCraft/Models/PrototypeScreen.swift`, `PaperCraft/Models/CanvasElement.swift`, `PaperCraft/Models/NormalizedFrame.swift` (doc: y 1'i geçebilir), `PaperCraft/Resources/Catalog/ComponentCatalog.json` (navigationBar, tabBar → `"scrollBehavior": "fixed"`)
- Test: `PaperCraftTests/ScrollingPageTests.swift`

**Interfaces:**
- Produces: `enum ScrollBehavior: String, Codable, CaseIterable { case fixed, scrolls; var title: String }`; `ElementProperties.scrollBehavior: ScrollBehavior?`; `CanvasElement.isPinned: Bool` (üst bar / alt menü ve `scrollBehavior != .scrolls`); `PrototypeScreen.contentHeight: Double` (ekran yüksekliği birimi, ≥ 1); `PrototypeScreen.endMargin: Double = 24 / 852`.

- [ ] **Step 1:** Testler: `emptyPageIsOneScreen` (1), `shortPageIsOneScreen` (eleman alt kenarı 0.8 → 1), `longPageEndsBelowLowestElement` (eleman y 1.5 h 0.1 → 1.6 + 24/852), `pinnedBarsDoNotCount` (sabit tabBar y 0.9 + serbest eleman 1.2 → 1.2 + h + pay), `scrollingBarCounts`, `catalogBarsAreFixed`, `unknownScrollBehaviorFallsBackToFixed`.
- [ ] **Step 2:** Çalıştır, derleme hatasıyla düşsün.
- [ ] **Step 3:** Uygula.
- [ ] **Step 4:** Testler geçsin.

### Task 2: ViewModel — görünen alana ekleme, alttan sınırsız taşıma/boyut

**Files:**
- Modify: `PaperCraft/ViewModels/EditorViewModel.swift`
- Test: `PaperCraftTests/ScrollingPageTests.swift`

**Interfaces:**
- Consumes: `CanvasElement.isPinned`.
- Produces: `EditorViewModel.visibleTop: Double` (görünen alanın üstü, ekran yüksekliği birimi; canvas yazar, kayıt/geri al'a girmez).

Kurallar: serbest elemanda `y ≥ 0`, üst sınır yok; sabit barda `0 … 1 − h`. `addElement`/`addSymbol` serbest elemanı `visibleTop + (1 − h)/2`'ye koyar, barlar katalog konumunda kalır. `resizeElement`, `setSelectedSize`, `duplicateSelectedElement` serbest elemanda alttan kırpmaz.

- [ ] **Step 1:** Testler: `addedElementLandsInVisibleArea` (visibleTop 2 → y ≈ 2 + (1−h)/2), `addedBarIgnoresScroll`, `freeElementMovesBelowFirstScreen` (dy 1.5 → y > 1), `freeElementStopsAtTop`, `pinnedBarStaysInsideViewport`, `resizeGrowsBelowFirstScreen`, `duplicateBelowFirstScreenIsNotClamped`, `undoRestoresElementBelowFirstScreen`.
- [ ] **Step 2–4:** düşür, uygula, geçir.

### Task 3: Kaydırma hesabı — `CanvasViewport.scroll`

**Files:**
- Modify: `PaperCraft/ViewModels/CanvasViewport.swift`
- Test: `PaperCraftTests/CanvasViewportTests.swift`

**Interfaces:**
- Produces: `CanvasViewport.scroll: CGFloat` (tuval point'i); `static func maxScroll(contentHeight: Double) -> CGFloat` (= contentHeight × 852); `static func dragged(from:by:cardSize:available:scale:contentHeight:) -> CanvasViewport` — dikey hareket önce `pan.height`'i sınırına kadar değiştirir, artan kısım `scroll -= artan / scale` olur, `0…maxScroll`'a kırpılır; yatay artan atılır.
- Mevcut `dragged(from:by:cardSize:available:)` bu yeni sürümle değiştirilir (tek çağıran `CanvasView`); mevcut testler yeni imzaya uyarlanır.

- [ ] **Step 1:** Testler: `fittedDragScrollsPage` (zoom 1, dy −200, scale 0.8 → scroll 250), `scrollStopsAtTop`, `scrollStopsOneScreenBelowContent` (contentHeight 1 → max 852), `zoomedDragPansThenScrolls` (zoom 2 pan sınırı 365, dy −500 → pan −365, scroll (500−365)/scale), `pinchKeepsScroll`.
- [ ] **Step 2–4.**

### Task 4: Editör — kayan canvas

**Files:**
- Modify: `PaperCraft/Views/Canvas/CanvasView.swift`, `PaperCraft/Views/Canvas/ScreenBackgroundView.swift`
- Create: `PaperCraft/Views/Canvas/PageEndLine.swift`

Davranış:
- İçerik katmanı (serbest elemanlar + arka plan) `-scroll` kadar yukarı çizilir; sabit barlar ayrı katmanda, kaymadan, en üstte (zIndex sıralaması kendi içinde korunur).
- Arka plan: geçiş `contentHeight × 852` boyunda; altında `ScreenBackgroundView.trailingColor` (son renk, yoksa kâğıt) ile dolgu.
- Pan hareketi artık zoom olmasa da açık (`including: .all`), `CanvasViewport.dragged(…scale:contentHeight:)` kullanılır.
- Kaydırma değiştikçe `viewModel.visibleTop = scroll / 852`.
- `PageEndLine`: `contentHeight > 1` iken `contentHeight × 852`'de kesik çizgi + "Sayfa sonu" etiketi, dokunulamaz.
- `liftForSelection` kaldırılır: Özellikler sayfası açılınca seçili eleman sayfanın altında kalacaksa `scroll` animasyonla artırılır (sabit barda yapılmaz). Seçilen sabit bar için hiçbir şey yapılmaz.
- Seçim çizgisi ve tutamaçlar elemanla birlikte kayar (içerik katmanının içinde).

- [ ] **Step 1:** Uygula; mevcut testler geçsin (`verify.sh`).
- [ ] **Step 2:** Simülatör (`-openEditor YES`): boş yerde yukarı sürükle → içerik kayar, sayfa sonu çizgisi görünmez (tek ekran); bir elemanı aşağı taşı → çizgi elemanın altında belirir; `-openProperties image` → sayfa açıkken başlık ile canvas yazıları üst üste binmez.

### Task 5: Üst bar / alt menü "Kaydırınca" seçeneği

**Files:**
- Modify: `PaperCraft/Views/Editor/NavigationBarPropertiesSheet.swift`, `PaperCraft/Views/Editor/TabBarPropertiesSheet.swift`

- [ ] **Step 1:** Her ikisine `Section("Kaydırınca") { OptionPicker(selection: viewModel.binding(\.scrollBehavior, default: .fixed), title: \.title) }`.
- [ ] **Step 2:** "Sayfayla kayar"a geçince bar `isPinned == false` olur; sabit katmandan içerik katmanına geçerken y değeri aynen kalır (görünen yer o an değişebilir — kabul).
- [ ] **Step 3:** Simülatör: `-openProperties navigationBar` ile seçeneği değiştir, editörde kaydırınca barın kaydığını gör.

### Task 6: Dene — uzun sayfada kaydırma

**Files:**
- Modify: `PaperCraft/Views/Preview/PreviewLayout.swift`, `PaperCraft/Views/Preview/PreviewView.swift`
- Test: `PaperCraftTests/PreviewTests.swift`

**Interfaces:**
- Produces: `PreviewLayout.scrollingCenter(of: NormalizedFrame) -> CGPoint` (= x aynı, y = `frame.y × 852 + h/2`, tuval point'i); `PreviewLayout.contentHeightPoints(for: PrototypeScreen) -> CGFloat` (= `max(designHeight, contentHeight × 852)`).

Davranış: `screen.contentHeight <= 1` → bugünkü kod yolu aynen. Uzunsa serbest elemanlar `ScrollView(.vertical)` içinde `scrollingCenter` ile; sabit barlar ScrollView dışında `center(of:)` ile (üst güvenli alanın altı / en alt). Aşağı çekip kapatma sadece kaydırma en üstteyken (`onScrollGeometryChange` ile `contentOffset.y <= 0`). Klavye kaldırma uzun sayfada ScrollView'ın kendi davranışına bırakılır.

- [ ] **Step 1:** Testler: `shortPageUsesStretchedLayout` (contentHeight 1 → `center` eskisiyle aynı değerler), `scrollingCenterUsesCanvasPoints` (y 1.5 h 0.1 → 1.5×852 + 42.6), `scrollingContentIsAtLeastScreenTall`.
- [ ] **Step 2–4.**
- [ ] **Step 5:** Simülatör: uzun sayfada Dene → kaydır, sabit üst bar/alt menü yerinde; en üstteyken aşağı çekince kapanır.

### Task 7: Sayfalar ızgarası ve küçük resim

**Files:**
- Modify: `PaperCraft/Views/Projects/ScreenThumbnail.swift`, `PaperCraft/Views/Projects/ProjectPagesView.swift`

Davranış: `ScreenThumbnail` gösterilen yükseklik = `min(contentHeight, 2) × 852`; içerik o boyda çizilir, sabit barlar ilk ekranın yerinde; `contentHeight > 2` ise altta soluklaşma maskesi. `ProjectPagesView` kart oranı aynı formülü kullanır (yer tutucu kart dahil). `ProjectCard` (Projelerim) ilk sayfayı tek ekran oranında göstermeye devam eder.

- [ ] **Step 1:** Uygula; simülatörde sayfalar ızgarasında uzun sayfanın kartı uzun.

### Task 8: Kenarda otomatik kaydırma

**Files:**
- Modify: `PaperCraft/Views/Canvas/CanvasView.swift`

Davranış: eleman sürüklenirken parmak kartın alt/üst 48 pt'lik şeridindeyse, bir `Timer` (≈60 Hz) `scroll`'u şeride girme derinliğiyle orantılı (en fazla 12 tuval pt/kare) değiştirir ve sürüklenen elemanın görüntüsü aynı miktarda kayar; bırakınca `moveElement`'e kaydırma farkı da eklenir. Zorsa bu task ertelenir ve yol haritasına not düşülür.

- [ ] **Step 1:** Uygula, simülatörde `touch_path` ile alta sürükle.

### Task 9: Bitiş

- [ ] `docs/yol_haritasi.md`: analiz listesinde "Kayan sayfa" `[x]` + not; Canvas / Önizleme maddelerine kısa not; test sayısı.
- [ ] `verify.sh` (iOS testleri, macOS derlemesi), simülatör turu.
- [ ] Kullanıcı onayıyla İngilizce commit.
