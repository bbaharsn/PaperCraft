"""VINS (Pascal VOC XML + JPEG) -> YOLO format converter."""
import random
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

CLASSES = ["text", "button", "textField", "image", "symbol", "box", "navigationBar", "switch"]

LABEL_MAP = {
    "Text": "text",
    "TextButton": "button",
    "EditText": "textField",
    "Image": "image",
    "BackgroundImage": "image",
    "Icon": "symbol",
    "Card": "box",
    "Toolbar": "navigationBar",
    "Switch": "switch",
}

Box = tuple[str, float, float, float, float]

NESTED_RATIO = 0.8
# inner label -> outer label that swallows it
NESTED_PAIRS = {"text": "textField", "symbol": "button"}


def _num(text: str) -> float:
    value = float(text)
    return int(value) if value.is_integer() else value


def parse_voc(path: Path) -> tuple[int, int, list[Box]]:
    root = ET.parse(path).getroot()
    size = root.find("size")
    width, height = int(size.findtext("width")), int(size.findtext("height"))
    boxes: list[Box] = []
    for obj in root.findall("object"):
        bb = obj.find("bndbox")
        boxes.append((
            obj.findtext("name"),
            _num(bb.findtext("xmin")), _num(bb.findtext("ymin")),
            _num(bb.findtext("xmax")), _num(bb.findtext("ymax")),
        ))
    return width, height, boxes


def map_and_filter(boxes: list[Box]) -> list[Box]:
    return [(LABEL_MAP[b[0]], *b[1:]) for b in boxes if b[0] in LABEL_MAP]


def _inside_ratio(inner: Box, outer: Box) -> float:
    iw = min(inner[3], outer[3]) - max(inner[1], outer[1])
    ih = min(inner[4], outer[4]) - max(inner[2], outer[2])
    area = (inner[3] - inner[1]) * (inner[4] - inner[2])
    if iw <= 0 or ih <= 0 or area <= 0:
        return 0.0
    return iw * ih / area


def drop_nested(boxes: list[Box]) -> list[Box]:
    kept = []
    for box in boxes:
        outer_label = NESTED_PAIRS.get(box[0])
        nested = outer_label is not None and any(
            o[0] == outer_label and _inside_ratio(box, o) >= NESTED_RATIO for o in boxes
        )
        if not nested:
            kept.append(box)
    return kept


def to_yolo_line(box: Box, width: int, height: int) -> str:
    label, xmin, ymin, xmax, ymax = box
    cx, cy = (xmin + xmax) / 2 / width, (ymin + ymax) / 2 / height
    w, h = (xmax - xmin) / width, (ymax - ymin) / height
    return f"{CLASSES.index(label)} {cx:.6f} {cy:.6f} {w:.6f} {h:.6f}"


def split(names: list[str], seed: int = 42) -> dict[str, list[str]]:
    shuffled = sorted(names)
    random.Random(seed).shuffle(shuffled)
    n_train, n_val = int(len(shuffled) * 0.70), int(len(shuffled) * 0.15)
    return {
        "train": shuffled[:n_train],
        "val": shuffled[n_train:n_train + n_val],
        "test": shuffled[n_train + n_val:],
    }


def convert(src: Path, out: Path) -> None:
    items = {}  # prefixed name -> (image path, yolo lines)
    skipped = []
    for xml in sorted(src.glob("*/Annotations/*.xml")):
        folder = xml.parent.parent
        image = folder / "JPEGImages" / f"{xml.stem}.jpg"
        if not image.exists():
            skipped.append(str(xml))
            continue
        width, height, boxes = parse_voc(xml)
        boxes = drop_nested(map_and_filter(boxes))
        items[f"{folder.name}_{xml.stem}"] = (image, [to_yolo_line(b, width, height) for b in boxes])

    counts = Counter()
    sets = split(list(items))
    for set_name, names in sets.items():
        (out / set_name / "images").mkdir(parents=True, exist_ok=True)
        (out / set_name / "labels").mkdir(parents=True, exist_ok=True)
        for name in names:
            image, lines = items[name]
            link = out / set_name / "images" / f"{name}.jpg"
            if link.is_symlink() or link.exists():
                link.unlink()
            link.symlink_to(image.resolve())
            (out / set_name / "labels" / f"{name}.txt").write_text("".join(l + "\n" for l in lines))
            counts.update(CLASSES[int(l.split()[0])] for l in lines)

    print({k: len(v) for k, v in sets.items()}, f"skipped (no image): {len(skipped)}")
    for cls in CLASSES:
        print(f"{cls:14s} {counts[cls]}")


if __name__ == "__main__":
    convert(Path(sys.argv[1]).expanduser(), Path(sys.argv[2]))
