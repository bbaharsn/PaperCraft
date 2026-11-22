# Kutuyu çöz — uygulama planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tek bir kutu seçiliyken "Kutuyu çöz" düğmesiyle yalnızca kutuyu silmek. İçindekiler yerinde kalır ve toplu seçimde seçili gelir.

**Architecture:** Mantık `EditorViewModel+Group.swift` içinde olacak: içindekiler `movingGroup(for:)` ile bulunur, kutu diziden çıkarılır, tek atamayla yazılır (tek geri al adımı). Görünüm tarafında `SelectionToolbar` dosyasına isteğe bağlı bir `onUngroup` kapanışı eklenir ve `EditorView` bu kapanışı `canUngroupSelected` doğruysa verir.

**Tech Stack:** SwiftUI, Swift Testing, iOS + macOS.

**Spec:** `docs/superpowers/specs/2026-11-22-ungroup-box-design.md`

## Global Constraints
- Düğme metni tam olarak: `Kutuyu çöz`. Sıra: `[Kutuyu çöz] [Çoğalt] [Sil]`.
- Toplu modda "Kutuyu çöz" düğmesi gösterilmez.
- Çözme tek geri al adımıdır.
- macOS'ta da derlenmeli.

## Review Focus
- İç içe kutu: yalnızca dıştaki çözülür, içteki kutu ve onun içindekiler kalır → test: `ungroupNestedKeepsInnerBox`.
- İçi boş kutu ya da kutu olmayan eleman: `canUngroupSelected == false`, `ungroupSelectedBox()` hiçbir şey yapmaz → test: `cannotUngroupEmptyBoxOrNonBox`.
- Geri al: kutu ve sıra eskisi gibi döner → test: `ungroupIsOneUndoStep`.
- Kutunun dışındaki elemanlar etkilenmez → `ungroupRemovesOnlyBoxAndSelectsContents` içinde buton kontrolü.

---

### Task 1: `ungroupSelectedBox()` ve `canUngroupSelected`

**Files:**
- Modify: `PaperCraft/ViewModels/EditorViewModel+Group.swift`
- Test: `PaperCraftTests/MultiSelectTests.swift`

**Interfaces:**
- Produces: `var canUngroupSelected: Bool` (seçili eleman `.box` ve `movingGroup(for: [id])` kutudan başka en az bir eleman içeriyor), `func ungroupSelectedBox()` (kutuyu siler; `isMultiSelecting = true`, `multiSelection` = içindekiler, `selectedElementID = nil`).

- [ ] **Step 1: Testleri yaz** (`boxScene()` yardımcısını kullan)
  - `ungroupRemovesOnlyBoxAndSelectsContents`: `select(box)` → `canUngroupSelected == true` → `ungroupSelectedBox()` → `screen.elements.map(\.id)` içinde `box` yok, `symbol` ve `button` var. `isMultiSelecting == true`, `multiSelection == [symbol]`, `selectedElementID == nil`. Sembolün frame'i değişmemiş.
  - `ungroupIsOneUndoStep`: `select(box)`, `before = screen` → çöz → `undoStack.count == 1` → `undo()` → `screen == before`.
  - `cannotUngroupEmptyBoxOrNonBox`: içi boş bir kutu seçiliyken ve `button` seçiliyken `canUngroupSelected == false`. `ungroupSelectedBox()` sonrası ekran değişmemiş.
  - `ungroupNestedKeepsInnerBox`: dış kutu (0.1, 0.1, 0.8×0.4), iç kutu (0.15, 0.15, 0.4×0.2), iç kutunun içinde bir sembol (0.2, 0.2, 0.1×0.05). Dış kutu çözülünce iç kutu ve sembol kalır, `multiSelection == [inner, symbol]`.
- [ ] **Step 2: Çalıştır, derleme hatasıyla düştüğünü gör** (`ungroupSelectedBox` tanımlı değil)
- [ ] **Step 3: Uygula.** `screen.elements.removeAll { $0.id == boxID }` tek atama olarak yapılır. İçindekiler `movingGroup(for: [boxID]).subtracting([boxID])`.
- [ ] **Step 4: Testler geçiyor**

### Task 2: "Kutuyu çöz" düğmesi

**Files:**
- Modify: `PaperCraft/Views/Editor/SelectionToolbar.swift` (`var onUngroup: (() -> Void)? = nil`, düğme `Çoğalt`'tan önce, görünüm "Kutuya al" ile aynı, ikon `square.slash`)
- Modify: `PaperCraft/Views/Editor/EditorView.swift:243` (`onUngroup: viewModel.canUngroupSelected ? { viewModel.ungroupSelectedBox() } : nil`)

- [ ] **Step 1: Uygula. Önizlemeye `SelectionToolbar(onUngroup: {}, onDuplicate: {}, onDelete: {})` ekle**
- [ ] **Step 2: `verify.sh`: iOS testleri + macOS derlemesi**
- [ ] **Step 3: Simülatörde dene:** katalogdan bir kutu ve içine bir sembol ekle, kutuyu seç, "Kutuyu çöz" düğmesine bas. Kutu gider, sembol kesikli çizgiyle seçili kalır. Geri al kutuyu geri getirir.
- [ ] **Step 4: Yol haritası (`docs/yol_haritasi.md`, "Çoklu seçim" maddesi): "kutudan çıkarma" eksiğini kaldır, yapılanı yaz. Commit kullanıcı onayıyla.**
