# Toplu Seçim ve Kutunun Kap Olması — Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kullanıcı üst bardaki bir düğmeyle toplu seçim moduna girip birkaç elemanı birlikte taşıyıp silebilsin. Bir Kutu sürüklenince ya da silinince içindeki elemanlar da onunla birlikte gelsin.

**Architecture:** "İçindekiler" bağı modele kaydedilmez. Her taşıma ya da silmede konumlardan saf bir yardımcıyla (`BoxContents`) hesaplanır. Grup taşıma tek parça sınırlanır (`GroupMove`) ve `screen`'e **tek atama** ile yazılır, böylece tek geri al adımı olur. Toplu seçim durumu `EditorViewModel`'de tutulur. `CanvasView` tek `draggingID` yerine bir küme taşır ve kesikli çerçeveleri çizer.

**Tech Stack:** Swift, SwiftUI (iOS + macOS), Swift Testing (`@Test`, `#expect`), xcodebuild.

**Spec:** `docs/superpowers/specs/2026-11-11-multi-select-design.md`

## Global Constraints

- Önce iPhone. Mevcut hareketler (çift dokunma, uzun basma, iki parmakla yakınlaştırma, boş alanda kaydırma, kenarda otomatik kaydırma) bozulmamalı.
- Her yeni tür kendi dosyasında olur. Yorumlar ve kullanıcıya görünen metinler Türkçe.
- Sürükleme sırasında model değişmez, yalnızca görüntü kayar. Model bırakınca tek seferde güncellenir.
- `screen` her atamada geri al yığınına yazar (`didSet`). Çok elemanlı bir değişiklik **tek atama** olmalıdır: önce `var elements = screen.elements` üzerinde çalış, en sonda `screen.elements = elements` ata.
- Sabit üst bar ve alt menü (`isPinned`) hiçbir gruba girmez.
- Sıra değiştirme (öne getirme) geri al adımı sayılmaz (`withoutRecording`).
- Henüz commit edilmemiş hizalama çizgisi (snap) çalışması bunun temelidir. İlk commit'ten önce kullanıcıya snap işinin ayrı commit edilip edilmeyeceğini sor.
- Commit mesajları İngilizce ve maddeli olur.
- Testleri çalıştırmak için: `~/.claude/skills/papercraft-verify-and-ship/scripts/verify.sh /Users/baharsen/Documents/PaperCraft <scratchpad>/dd` (2–5 dk, zaman aşımı 600000 ms). Betik geçen/kalan sayısını yazar ve macOS'u da derler. SourceKit uyarılarına değil, xcodebuild çıktısına güven.

## Review Focus

1. **Kutu seçilince içindekileri örtmesi:** Normal modda bir Kutu'ya dokunmak onu ve içindekileri öne getirmeli, içindekiler kutunun üstünde kalmalı → Task 3, `selectingBoxKeepsContentsOnTop`.
2. **Grup sayfa kenarına dayanınca aradaki boşluğun bozulması:** Grup tek parça durmalı → Task 2, `clampsWholeGroupAtLeftEdge`.
3. **Kutu içinde görünen sabit üst bar:** Gruba girmemeli → Task 1, `pinnedElementIsNeverContent`.
4. **Toplu silme sonrası geri alma:** Tek adımda hepsi eski sırasıyla geri gelmeli → Task 3, `deletingBoxIsOneUndoStepAndRestoresOrder`.
5. **Mod açıkken geri alma, seçili elemanı silen bir hale dönerse:** Seçimde artık olmayan kimlik kalmamalı → Task 3, `undoPrunesMultiSelection`.

---

### Task 1: İçindekileri bulma (`BoxContents`)

**Files:**
- Create: `PaperCraft/ViewModels/BoxContents.swift`
- Test: `PaperCraftTests/BoxContentsTests.swift`

**Interfaces:**
- Produces:
  `nonisolated enum BoxContents { static func group(startingFrom ids: Set<UUID>, in elements: [CanvasElement], rect: (CanvasElement) -> CGRect) -> Set<UUID> }`
  Dönen küme: verilen kimlikler (sabit olanlar hariç) + bunlar arasındaki her Kutu'nun içindekiler. `rect`, elemanın point dikdörtgenidir (çağıran `viewModel.pointRect(of:)` verir). Döndürme hesabını fonksiyon kendisi `SnapGuides.boundingBox(rect(e), degrees: e.properties.rotation ?? 0)` ile yapar.

**Kural:** Bir eleman, bir Kutu'nun içindedir, eğer (a) dizide kutudan sonra geliyorsa, (b) `!isPinned` ise ve (c) döndürülmüş kutusu kutunun dikdörtgeninin içindeyse (0.5 pt pay ile: `box.insetBy(dx: -0.5, dy: -0.5).contains(child)`). İç içe kutular için içteki kutunun içindekileri de eklenir (sabit noktaya kadar tekrar et ya da tek geçişte "dış kutunun içindeki her şey"). İki yöntem de aynı sonucu verir.

- [ ] **Step 1: Write the failing tests** — `BoxContentsTests` içinde `CanvasElement(type:frame:properties:)` ile elle eleman kur. `rect` olarak normalize frame'i 100 ile çarpan basit bir kapanış kullan.

```swift
@Test func elementFullyInsideAndAboveBoxIsContent()      // kutu [0], sembol [1] içinde → group([kutu]) == [kutu, sembol]
@Test func elementBelowBoxInOrderIsNotContent()          // sembol [0], kutu [1] → group([kutu]) == [kutu]
@Test func elementPartlyOutsideIsNotContent()            // yazı kutudan 2 pt taşıyor → dahil değil
@Test func nestedBoxBringsItsContents()                  // dış kutu, iç kutu, iç kutunun içindeki yazı → üçü
@Test func pinnedElementIsNeverContent()                 // kutunun içinde duran sabit navigationBar → dahil değil; group([navBar]) == []
@Test func nonBoxSelectionStaysAsIs()                    // group([sembol]) == [sembol] (sembolün altında başka şey olsa bile)
@Test func rotatedChildUsesBoundingBox()                 // 45° döndürülmüş ve köşesi taşan sembol → dahil değil
```

- [ ] **Step 2: Run tests, expect failure** (`BoxContents` tanımlı değil, derleme hatası).
- [ ] **Step 3: Implement `BoxContents.group(startingFrom:in:rect:)`** — yukarıdaki kural.
- [ ] **Step 4: Run tests, expect all green.**
- [ ] **Step 5: Commit** — `Add BoxContents to find elements inside a box`.

---

### Task 2: Grup taşıma sınırı (`GroupMove`)

**Files:**
- Create: `PaperCraft/ViewModels/GroupMove.swift`
- Test: `PaperCraftTests/GroupMoveTests.swift`

**Interfaces:**
- Produces:
  `nonisolated enum GroupMove { static func clamped(dx: Double, dy: Double, frames: [NormalizedFrame], keepsOnScreen: Bool) -> (dx: Double, dy: Double) }`
  Normalize birimlerle. `frames`'in ortak sınırı: `minX = min(x)`, `maxX = max(x + width)`, `minY = min(y)`, `maxY = max(y + height)`. Sonuç: `dx ∈ [-minX, 1 - maxX]`, `dy ≥ -minY`, `keepsOnScreen` ise ayrıca `dy ≤ 1 - maxY`. Bu, mevcut `moveElement` kurallarının grup halidir (tek sabit eleman için `keepsOnScreen: true`).

- [ ] **Step 1: Write the failing tests**

```swift
@Test func passesThroughWhenInside()             // frames x 0.2…0.4 ve 0.5…0.6, dx 0.1 → dx 0.1
@Test func clampsWholeGroupAtLeftEdge()          // minX 0.1, dx -0.3 → dx -0.1 (iki eleman arası fark korunur)
@Test func clampsWholeGroupAtRightEdge()         // maxX 0.9, dx 0.3 → dx 0.1
@Test func clampsAtTopButNotBottom()             // minY 0.05, dy -0.2 → -0.05; dy 5 → 5
@Test func keepsOnScreenClampsBottom()           // keepsOnScreen, maxY 0.95, dy 0.2 → 0.05
```

- [ ] **Step 2: Run tests, expect failure.**
- [ ] **Step 3: Implement `GroupMove.clamped`.**
- [ ] **Step 4: Run tests, expect green.**
- [ ] **Step 5: Commit** — `Add GroupMove to clamp a group move as one piece`.

---

### Task 3: Editör modeli — toplu seçim, grup taşıma, öne getirme, silme

**Files:**
- Modify: `PaperCraft/ViewModels/EditorViewModel.swift` (saklanan özellikler, `select(_:)`, `deleteSelectedElement()`, `restore(_:)`, `moveElement`)
- Create: `PaperCraft/ViewModels/EditorViewModel+Group.swift` (yeni metotlar burada, `extension EditorViewModel`)
- Test: `PaperCraftTests/MultiSelectTests.swift`

**Interfaces:**
- Consumes: `BoxContents.group(startingFrom:in:rect:)`, `GroupMove.clamped(dx:dy:frames:keepsOnScreen:)`
- Produces (`EditorViewModel`):
  - `var isMultiSelecting: Bool` (başta `false`) ve `var multiSelection: Set<UUID>` (başta boş). Saklanan özellik oldukları için ana sınıfta tanımlanır. Ekran durumu değiller, geri al'a girmezler.
  - `func toggleMultiSelectMode()` → modu çevirir, `selectedElementID = nil`, `multiSelection = []`.
  - `func toggleInMultiSelection(_ id: UUID)` → ekler ya da çıkarır. Sabit eleman eklenmez. Sıra değişmez.
  - `func clearMultiSelection()`
  - `func movingGroup(for ids: Set<UUID>) -> Set<UUID>` → `BoxContents.group(startingFrom: ids, in: screen.elements, rect: pointRect(of:))`.
  - `func bringToFront(_ ids: Set<UUID>)` → kümedeki elemanlar kendi aralarındaki sırayı koruyarak dizinin sonuna taşınır, `withoutRecording` içinde.
  - `func moveGroup(_ ids: Set<UUID>, dx: Double, dy: Double)` → `GroupMove.clamped` ile (`keepsOnScreen`: kümede sabit eleman varsa `true`), **tek atamayla** yazar. `moveElement(_:dx:dy:)` artık `moveGroup([id], dx:dy:)`'u çağırır.
  - `func deleteMultiSelection()` → `movingGroup(for: multiSelection)` içindeki her şeyi tek atamayla siler, `multiSelection = []`.
  - Değişen davranış: `select(_ id:)` artık `bringToFront(movingGroup(for: [id]))` yapar (Kutu değilse bu bugünkü davranışın aynısı). `deleteSelectedElement()` artık `movingGroup(for: [id])`'yi tek atamayla siler. `restore(_:)` ayrıca `multiSelection`'dan artık olmayan kimlikleri atar.

Testlerde `DuplicateTests`'teki gibi `EditorViewModel(catalog: try ComponentCatalog.load(), screen: PrototypeScreen(name: "Test"))` kur. Kutu + içindeki sembol için elemanları `screen.elements`'e frame'leri elle vererek koy, sonra geri al yığınını temiz başlatmak için yeni bir `EditorViewModel` oluştur (ya da `screen:` parametresiyle doğrudan ver).

- [ ] **Step 1: Write the failing tests**

```swift
@Test func toggleModeClearsSelection()                    // seçili eleman var → toggle → selectedElementID nil, mod açık; tekrar toggle → kapalı, multiSelection boş
@Test func tapTogglesMembershipWithoutReordering()        // iki eleman; ilkini toggle → içinde, dizi sırası aynı; tekrar → dışında
@Test func pinnedElementCannotJoinMultiSelection()
@Test func selectingBoxKeepsContentsOnTop()               // [kutu, sembol, buton(kutu dışında)] → select(kutu) → sıra [buton, kutu, sembol]
@Test func movingGroupIsOneUndoStep()                     // moveGroup([a, b], dx: 0.1, dy: 0.1) → undoStack.count +1; undo → ikisi de eski yerinde
@Test func moveGroupKeepsSpacingAtEdge()                  // a.x 0.1, b.x 0.5, dx -0.3 → a.x 0, b.x 0.4
@Test func deletingBoxDeletesContents()                   // select(kutu) + deleteSelectedElement → kutu ve sembol yok, buton duruyor
@Test func deletingBoxIsOneUndoStepAndRestoresOrder()     // sil → undo → elemanlar ve sıra silmeden önceki gibi; undoStack tek adım arttı
@Test func deleteMultiSelectionDeletesAllAndBoxContents() // multiSelection [kutu, buton] → sembol de silinir; multiSelection boş
@Test func undoPrunesMultiSelection()                     // eleman ekle (adım 1), mod aç, onu seç, undo → multiSelection boş
```

- [ ] **Step 2: Run tests, expect failure.**
- [ ] **Step 3: Implement the properties and methods above.** Mevcut `UndoTests`, `DuplicateTests`, `ResizeTests` bozulmamalı.
- [ ] **Step 4: Run all tests, expect green** (önceki sayı + yeni testler).
- [ ] **Step 5: Commit** — `Add multi-select state, group move and box-aware delete to the editor`.

---

### Task 4: Canvas — grup sürükleme, kesikli çerçeveler, toplu modda dokunuşlar

**Files:**
- Create: `PaperCraft/Views/Canvas/DashedOutline.swift` — `struct DashedOutline: View { let scale: CGFloat }`. Elemanın çerçevesine kesikli bir dikdörtgen çizer. Çizgi ekranda yakınlaştırmadan bağımsız sabit kalınlıkta olur: `lineWidth: 1.5 / scale`, `dash: [4 / scale, 3 / scale]`, renk `SelectionOverlay` ile aynı. `allowsHitTesting(false)`.
- Create: `PaperCraft/Views/Canvas/GroupOutline.swift` — `struct GroupOutline: View { let rect: CGRect; let scale: CGFloat }`. Ortak çerçeveyi düz ince çizgiyle (`1 / scale`) çizer, `rect` sayfa point'iyle verilir.
- Modify: `PaperCraft/Views/Canvas/CanvasView.swift`

**Interfaces:**
- Consumes: Task 3'teki bütün `EditorViewModel` API'si.

**CanvasView değişiklikleri:**
1. `@State private var draggingID: UUID?` yerine `@State private var draggingIDs: Set<UUID> = []`. Kullanıldığı her yer güncellenir (yakınlaştırma iptali, uzun basma koşulu, `guidesLayer`'daki `mover`: kümedeki ilk eleman yeterli, çünkü sabit eleman yalnız taşınır).
2. Sürükleme başlarken (`draggingIDs.isEmpty` iken):
   - Toplu mod **kapalı**: `viewModel.select(element.id)` (bu zaten kutu + içindekileri öne getirir), sonra `draggingIDs = viewModel.movingGroup(for: [element.id])`.
   - Toplu mod **açık**: `let start = viewModel.multiSelection.contains(element.id) ? viewModel.multiSelection : [element.id]`, sonra `draggingIDs = viewModel.movingGroup(for: start)` ve `viewModel.bringToFront(draggingIDs)`. Seçim değişmez.
3. Kaydırma (`offset`), `draggingIDs`'teki her elemana uygulanır.
4. Hizalama: taşınan dikdörtgen, gruptaki elemanların `snapBox`'larının birleşimidir. Hedefler, `draggingIDs` dışındaki elemanlardır. `snapped(...)` imzası `snapped(_ ids: Set<UUID>, lead: CanvasElement, translation:scale:)` olur. Katman hesabı için `lead` kullanılır.
5. Bırakınca: `viewModel.moveGroup(draggingIDs, dx:, dy:)` (bugünkü `moveElement` çağrısının yerine, aynı sıfır-hareket koruması ile).
6. Kesikli çerçeveler: bir eleman `draggingIDs.count > 1` iken kümedeyse **ya da** toplu mod açıkken `multiSelection`'daysa `.overlay { DashedOutline(scale:) }` alır. Bu çerçeve, eleman ile birlikte döner ve kayar (mevcut `SelectionOverlay` ile aynı yere eklenir).
7. Ortak çerçeve: toplu mod açıkken ve `multiSelection` boş değilken, kayan sayfa katmanında (elemanlardan sonra, `zIndex` en yüksek) `GroupOutline` çizilir. `rect`, seçili ve sabit olmayan elemanların `SnapGuides.boundingBox(pointRect)` birleşimidir. Sürükleme sırasında `dragOffset` ve `edgeScrolled` kadar kaydırılır.
8. Toplu mod açıkken:
   - Tek dokunuş → `viewModel.toggleInMultiSelection(element.id)` (`select` değil).
   - Çift dokunuş ve uzun basma kapanışları hiçbir şey yapmaz (`guard !viewModel.isMultiSelecting`).
   - `SelectionOverlay` (tutamaçlar) gösterilmez.
   - Boş yere tek dokunuş `viewModel.clearMultiSelection()` yapar. Çift dokunuş Arka Plan'ı açmaz.
   Not: Çift dokunuşta tek dokunuş iki kez gelir ve eleman seçilip geri çıkar. Bu kabul edildi.
9. `revealSelection` toplu modda bir şey yapmaz (`selectedElement` zaten `nil`).

- [ ] **Step 1: Implement `DashedOutline` and `GroupOutline`** (her biri kendi dosyasında, `#Preview` ile).
- [ ] **Step 2: Implement CanvasView changes 1–9.**
- [ ] **Step 3: Run all tests + macOS build, expect green.** `SnapGuidesTests`, `RotationTests`, `ScrollingPageTests` dahil.
- [ ] **Step 4: Commit** — `Drag groups on the canvas with dashed outlines and multi-select taps`.

---

### Task 5: Üst bar düğmesi ve editör bağlantısı

**Files:**
- Modify: `PaperCraft/Views/Editor/EditorTopBar.swift` — `var isMultiSelecting = false`, `var onToggleMultiSelect: () -> Void = {}`. Katalog düğmesinin **solunda** yeni bir düğme: ikon `square.on.square.dashed`, 44×44, `catalogButton` ile aynı çerçeve. Açıkken zemin `Theme.ink`, ikon `Theme.paper`. `accessibilityLabel("Toplu seçim")`, `.accessibilityAddTraits(isMultiSelecting ? .isSelected : [])`. `#Preview`'a açık hali de eklenir.
- Modify: `PaperCraft/Views/Editor/EditorView.swift`

**EditorView davranışı:**
1. `onToggleMultiSelect`: `viewModel.toggleMultiSelectMode()`. Mod açıldıysa `wantsProperties = false`, `isEditingBackground = false`, katalog açıksa `withAnimation(.snappy) { isCatalogOpen = false }`.
2. `onToggleCatalog`: katalog açılırken mod açıksa önce `viewModel.toggleMultiSelectMode()` (mod kapanır, seçim temizlenir).
3. `SelectionToolbar` koşulu: toplu modda `!viewModel.multiSelection.isEmpty`, normal modda bugünkü gibi `selectedElementID != nil`. Toplu modda `onDuplicate: nil`, `onDelete: { viewModel.deleteMultiSelection() }`. Animasyon `multiSelection.isEmpty`'yi de izler.

- [ ] **Step 1: Implement the top bar button.**
- [ ] **Step 2: Wire EditorView 1–3.**
- [ ] **Step 3: Run all tests + macOS build, expect green.**
- [ ] **Step 4: Simülatörde dene** (`papercraft-verify-and-ship` bölüm 2). Bir Kutu koy, içine Sembol ve Yazı bırak:
  - Kutuyu sürükle → üçü birlikte kayar, kesikli çerçeveler görünür. Geri al → tek adımda eski yerine döner.
  - Kutuya dokun → içindekiler kutunun üstünde kalır.
  - Toplu modu aç, iki elemana dokun → kesikli çerçeveler ve ortak çerçeve görünür, Sil görünür ama Çoğalt görünmez. Birini sürükle → ikisi kayar. Sil → ikisi de silinir.
  - Kutuyu sil → içindekiler de silinir, geri al hepsini geri getirir.
  - Ekran görüntüsü al.
- [ ] **Step 5: Yol haritasını güncelle** (`docs/yol_haritasi.md`, çoklu seçim maddesi) ve commit et — `Add a multi-select button to the editor top bar`.
