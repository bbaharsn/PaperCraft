# UI Element Detector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Train a YOLO model on VINS, ship it with Core ML, and let the user add a page from a photo or camera scan whose detected elements land on the canvas.

**Architecture:** A Python `ml/` folder converts VINS (Pascal VOC) to YOLO format, trains `yolo11n`, evaluates it, and exports `PaperCraftDetector.mlpackage`. In the app, `ElementDetector` (same pattern as `BackgroundRemover`) runs the model through Vision. A pure mapping function turns the boxes into `CanvasElement`s using catalog defaults. `Project.addScreen(elements:)` stores them as a new page.

**Tech Stack:** Python 3 + `ultralytics` + `pytest`; Swift, Vision, Core ML, VisionKit (`VNDocumentCameraViewController`), PhotosUI (`PhotosPicker`), Swift Testing.

**Spec:** `docs/superpowers/specs/2026-11-25-ui-detector-design.md`

## Global Constraints

- Training runs on the Mac: `device="mps"`, `imgsz=640`, `epochs=50` with early stopping.
- Split is 70 / 15 / 15 (train / val / test) with a fixed seed (`42`).
- Class names are `ElementType` raw values, in this fixed order: `text, button, textField, image, symbol, box, navigationBar, switch`.
- Never commit the dataset, `ml/data/`, `ml/runs/`, `ml/.venv/` or `*.pt`. Do commit `PaperCraftDetector.mlpackage`.
- Detection is on-device only. The image never leaves the device.
- Downscale images before detection (longest side 1024 px). See the memory-safe code rule.
- Minimum iOS 17.6 / macOS 14.6. The camera scanner is iOS-only. On macOS, only the image picker is shown.
- Teaching mode: before each step, Bahar gets a short "what / why" explanation and the code. `ml/README.md` keeps that text in Turkish.
- Commits use English bullet messages.

## Review Focus

1. **Very large photo (e.g. 48 MP camera image):** it must be downscaled before Vision so memory does not spike. Pinned in Task 4 (`downscaled` test).
2. **Image where nothing is detected (a landscape photo, a blank page):** no empty page gets created; the user sees "Bu görselde eleman bulunamadı" and can retry. Pinned in Task 4 (empty result) and Task 5 (UI state).
3. **Box slightly outside the image (Vision returns -0.01 or 1.02):** the frame is clamped to 0...1. Pinned in Task 4.
4. **Text box inside a text field (placeholder) in the training data:** dropped during conversion, so no stacked duplicate element appears. Pinned in Task 1.
5. **macOS build:** VisionKit's document camera does not exist there. The camera option is compiled out and the macOS build still succeeds. Pinned in Task 5 verification.

---

### Task 1: Python setup and VINS → YOLO converter

**Files:**
- Create: `ml/requirements.txt`, `ml/convert_vins.py`, `ml/vins.yaml`, `ml/README.md`, `ml/tests/test_convert_vins.py`
- Modify: `.gitignore` (add `ml/data/`, `ml/runs/`, `ml/.venv/`, `*.pt`)

**Interfaces:**
- Produces:
  - `CLASSES: list[str]` = the global class order
  - `LABEL_MAP: dict[str, str]` = `{"Text":"text","TextButton":"button","EditText":"textField","Image":"image","BackgroundImage":"image","Icon":"symbol","Card":"box","Toolbar":"navigationBar","Switch":"switch"}` (everything else, including `UpperTaskBar`, is dropped)
  - `Box = tuple[str, float, float, float, float]` (label, xmin, ymin, xmax, ymax in pixels)
  - `parse_voc(path: Path) -> tuple[int, int, list[Box]]` (width, height, VINS-labelled boxes)
  - `map_and_filter(boxes: list[Box]) -> list[Box]` (mapped labels only)
  - `drop_nested(boxes: list[Box]) -> list[Box]` (drops `text` whose area is ≥80% inside a `textField`, and `symbol` ≥80% inside a `button`)
  - `to_yolo_line(box: Box, width: int, height: int) -> str` (`"<class_idx> cx cy w h"`, 6 decimals)
  - `split(names: list[str], seed: int = 42) -> dict[str, list[str]]` (keys `train`/`val`/`test`)
  - CLI: `python convert_vins.py "<All Dataset path>" data/` writes `data/{train,val,test}/{images,labels}/`

- [ ] **Step 1:** Create `ml/.venv` and `requirements.txt` with `ultralytics` and `pytest` pinned to the installed versions. Run `ml/.venv/bin/pip install -r ml/requirements.txt`. Expected: install succeeds.
- [ ] **Step 2: Write failing tests** in `ml/tests/test_convert_vins.py`:

```python
def test_map_drops_status_bar_and_unknown():
    boxes = [("UpperTaskBar",0,0,375,20), ("Drawer",0,0,10,10), ("TextButton",10,10,50,30)]
    assert map_and_filter(boxes) == [("button",10,10,50,30)]

def test_drop_nested_placeholder_text():
    boxes = [("textField",0,0,100,40), ("text",5,5,60,35), ("text",0,100,50,120)]
    assert drop_nested(boxes) == [("textField",0,0,100,40), ("text",0,100,50,120)]

def test_drop_nested_icon_in_button():
    assert drop_nested([("button",0,0,100,40), ("symbol",4,4,30,36)]) == [("button",0,0,100,40)]

def test_to_yolo_line():
    assert to_yolo_line(("button",60,485,316,500), 375, 667) == "1 0.501333 0.738381 0.682667 0.022489"

def test_split_is_70_15_15_and_stable():
    names = [f"f{i}" for i in range(100)]
    a, b = split(names), split(names)
    assert a == b and [len(a[k]) for k in ("train","val","test")] == [70,15,15]
    assert set(a["train"]) | set(a["val"]) | set(a["test"]) == set(names)

def test_parse_voc(tmp_path): # write a 1-object XML like Wireframes/Annotations/wf_0.xml
    ...  # expect (375, 667, [("Image",168,263,209,305)])
```

- [ ] **Step 3:** Run `cd ml && .venv/bin/pytest -q`. Expected: FAIL (module not found).
- [ ] **Step 4:** Implement the functions in `ml/convert_vins.py` (`xml.etree.ElementTree`, `random.Random(seed).shuffle` on sorted names). The CLI walks every `*/Annotations/*.xml`, finds the image in the sibling `JPEGImages` (skips the file if missing), and prefixes output names with the subfolder (`iphone_123.jpg`) to avoid name clashes. Write `vins.yaml` (`path: data`, `train/val/test` image dirs, `names:` = `CLASSES`).
- [ ] **Step 5:** Run `.venv/bin/pytest -q`. Expected: all pass.
- [ ] **Step 6:** Run the CLI on `~/Downloads/All Dataset`. Expected: about 4,800 images split ≈ 3,360 / 720 / 720. Print per-class box counts and share them with Bahar (teaching moment: class imbalance).
- [ ] **Step 7:** Write `ml/README.md` sections 1-3 (setup, label mapping, split — what and why). Commit.

### Task 2: Train and evaluate

**Files:**
- Create: `ml/train.py`, `ml/evaluate.py`, `ml/results.md`

**Interfaces:**
- Consumes: `ml/vins.yaml`, `ml/data/` from Task 1
- Produces: `ml/runs/detect/vins/weights/best.pt`; `evaluate.py <weights> [--data vins.yaml] [--split test]` prints a per-class precision / recall / mAP50 / mAP50-95 table

- [ ] **Step 1:** `train.py`: `YOLO("yolo11n.pt").train(data="vins.yaml", epochs=50, patience=10, imgsz=640, device="mps", name="vins", fliplr=0.0, perspective=0.0005, hsv_v=0.4, hsv_s=0.5, degrees=2)`. Explain each argument to Bahar before running.
- [ ] **Step 2:** Run training in the background (`run_in_background`, it takes hours). Expected: `best.pt` exists, and the val mAP50 curve rises then flattens. Walk through `results.png` with Bahar (loss vs. epoch, overfitting signs).
- [ ] **Step 3:** `evaluate.py` runs `YOLO(weights).val(data=..., split="test")` and prints a markdown table from `metrics.box` (per-class `p`, `r`, `ap50`, `ap`).
- [ ] **Step 4:** Run it on the test split. Write the table to `ml/results.md` with date, dataset size and settings. Expected: a table with all 8 classes. Flag weak classes (expected: `switch`, `navigationBar`).
- [ ] **Step 5:** Review the worst predictions with Bahar (`val` saves `val_batch*_pred.jpg`). Decide whether one retraining round is worth it. Write README section 4 (training and metrics). Commit.

### Task 3: Core ML export, add to app, licenses

**Files:**
- Create: `ml/export.py`, `PaperCraft/Resources/ML/PaperCraftDetector.mlpackage`, `PaperCraft/Resources/Licenses/VINS-LICENSE.txt`, `PaperCraft/Resources/Licenses/Ultralytics-AGPL.txt`
- Modify: `PaperCraft/Models/License.swift` (two entries in `License.all`), `PaperCraftTests/LicenseTests.swift` (if it checks counts or files)

**Interfaces:**
- Produces: the Xcode-generated class `PaperCraftDetector`. Its output labels are exactly `CLASSES`.

- [ ] **Step 1:** `export.py`: `YOLO(best).export(format="coreml", nms=True, imgsz=640)`. Copy the result to `PaperCraft/Resources/ML/` (the folder is synchronized, so Xcode picks it up).
- [ ] **Step 2:** Find the VINS dataset's license and citation (its GitHub repo or paper) and save it as `VINS-LICENSE.txt`. Save the Ultralytics AGPL-3.0 text. Add both to `License.all`. If the VINS license forbids use, stop and tell Bahar.
- [ ] **Step 3:** Run the iOS tests (papercraft-verify-and-ship skill). Expected: everything passes, including `LicenseTests`. Commit.

### Task 4: `ElementDetector` service

**Files:**
- Create: `PaperCraft/Services/ElementDetector.swift`, `PaperCraftTests/ElementDetectorTests.swift`

**Interfaces:**
- Consumes: `PaperCraftDetector` (Task 3), `ComponentCatalog.makeElement(of:)`
- Produces:
  - `nonisolated struct DetectedBox: Equatable { let label: String; let confidence: Double; let visionBox: CGRect }` (Vision coordinates: normalized, origin bottom-left)
  - `nonisolated enum ElementDetector`
    - `static func elements(from boxes: [DetectedBox], catalog: ComponentCatalog, minimumConfidence: Double = 0.4) -> [CanvasElement]`: pure
    - `static func downscaled(_ image: CGImage, maxSide: Int = 1024) -> CGImage`
    - `static func detect(in image: CGImage) throws -> [DetectedBox]`: downscales, then runs `VNCoreMLRequest` and maps `VNRecognizedObjectObservation` (top label) to `DetectedBox`

- [ ] **Step 1: Write failing tests** (Swift Testing, `ComponentCatalog.load()` from the main bundle):

```swift
@Test func flipsYAndKeepsSize() {
    let box = DetectedBox(label: "button", confidence: 0.9, visionBox: CGRect(x: 0.1, y: 0.7, width: 0.5, height: 0.1))
    let e = ElementDetector.elements(from: [box], catalog: catalog).first!
    #expect(e.type == .button)
    #expect(e.frame.x.isApprox(0.1) && e.frame.y.isApprox(0.2) && e.frame.width.isApprox(0.5) && e.frame.height.isApprox(0.1))
    #expect(e.properties == catalog.makeElement(of: .button)!.properties)
}
@Test func dropsLowConfidenceAndUnknownLabels()  // confidence 0.3 → gone; label "drawer" → gone
@Test func clampsToUnitRange()                   // visionBox x: -0.02, maxY 1.03 → frame inside 0...1
@Test func sortsLargestFirst()                   // box (area 0.5) before text (area 0.01) → draw order
@Test func emptyInputGivesEmptyOutput()
@Test func downscaledLongestSideIs1024()         // 4000×3000 CGImage → 1024×768; 800×600 stays as is
```

- [ ] **Step 2:** Run the tests. Expected: FAIL (missing types).
- [ ] **Step 3:** Implement. The label is mapped with `ElementType(rawValue:)`, and `nil`/`.unknown` is skipped. `y = 1 - visionBox.maxY`. Clamping is done on the rect before conversion. Load the model once (`static let`).
- [ ] **Step 4:** Run the tests. Expected: PASS. Commit.

### Task 5: "Görselden sayfa ekle" in the project's pages

Pages are added from `ProjectPagesView` (the "Yeni sayfa" card calls `project.addScreen()`), so this button goes next to that card. It still adds to the open project, as the spec says. *(Plan-time deviation from the spec's "editor pages menu": the editor has no pages menu. The pages view is where the project's pages live.)*

**Files:**
- Modify: `PaperCraft/Models/Persistence/Project.swift` (`addScreen`), `PaperCraft/Views/Projects/ProjectPagesView.swift`, `PaperCraft.xcodeproj/project.pbxproj` (`INFOPLIST_KEY_NSCameraUsageDescription = "Bir tasarımın fotoğrafını çekip sayfaya dönüştürmek için kamera kullanılır."` in the iOS app target's Debug and Release configs)
- Create: `PaperCraft/Views/Projects/ImportScreenCard.swift`, `PaperCraft/Views/Projects/DocumentScanner.swift` (`#if os(iOS)`)
- Test: `PaperCraftTests/MultiScreenTests.swift`

**Interfaces:**
- Consumes: `ElementDetector.detect(in:)`, `ElementDetector.elements(from:catalog:)`
- Produces:
  - `Project.addScreen(elements: [CanvasElement] = []) -> ScreenRecord` (existing callers unchanged)
  - `struct DocumentScanner: UIViewControllerRepresentable` with `onScan: (CGImage) -> Void` and `onCancel: () -> Void` (first page of the scan)
  - `struct ImportScreenCard: View` with `project: Project` and `onOpen: (ScreenRecord) -> Void`

- [ ] **Step 1: Failing test:** `addScreenWithElementsStoresThem`: `project.addScreen(elements: [e1, e2]).screen?.elements == [e1, e2]`, and the name follows the "Sayfa N" rule.
- [ ] **Step 2:** Run it. Expected: FAIL. Add the parameter. Run again. Expected: PASS.
- [ ] **Step 3:** Build `ImportScreenCard`, styled like `addCard`, with the label "Görselden sayfa" and icon `photo.badge.plus`. Tapping opens a menu: "Fotoğraflardan seç" (`PhotosPicker`) and, on iOS only when `VNDocumentCameraViewController.isSupported`, "Kamerayla tara". While analysing, show a progress overlay ("Analiz ediliyor…"). Detection runs off the main actor (`Task.detached`). On success it calls `onOpen(project.addScreen(elements:))`. With zero elements it shows an alert "Bu görselde eleman bulunamadı" with "Tekrar dene" and "Vazgeç". On a thrown error it shows the same alert with the text "Görsel analiz edilemedi". The catalog is `ComponentCatalog.load().sized(for: project.device)`.
- [ ] **Step 4:** Add `INFOPLIST_KEY_NSCameraUsageDescription` and place `ImportScreenCard` after `addCard`.
- [ ] **Step 5:** Verify (papercraft-verify-and-ship). iOS tests pass. macOS build succeeds (no camera option). In the simulator, pick a screenshot from Photos → a new page opens with elements, and a blank image shows the alert. Camera scanning needs a real iPhone: ask Bahar to try it. Commit.

### Task 6: Real-world camera test set and wrap-up

**Files:**
- Create: `ml/camera_test/` (git-ignored images, committed `camera.yaml` only), and a row added to `ml/results.md`
- Modify: `docs/yol_haritasi.md`, `ml/README.md` (section 5)

- [ ] **Step 1:** Bahar takes about 20 phone photos of app screens (PaperCraft previews, other apps on another device), ideally through the scanner so they match real use. Label them in YOLO format with a local tool (e.g. the `makesense.ai` web app, which runs in the browser without uploading). Explain why this set must never be used for training.
- [ ] **Step 2:** Run `evaluate.py best.pt --data camera.yaml --split test` and add a "Kamera" row to `results.md`. Expected: a number, likely lower than the clean test set. Discuss the gap.
- [ ] **Step 3:** Update the roadmap (new AI detector item, CV-ready one-line summary in `results.md`). Write README section 5. Commit and push with Bahar's go-ahead.
