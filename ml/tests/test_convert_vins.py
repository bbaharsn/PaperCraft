import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from convert_vins import (  # noqa: E402
    drop_nested,
    map_and_filter,
    parse_voc,
    split,
    to_yolo_line,
)

VOC_XML = """<annotation>
    <filename>wf_0.jpg</filename>
    <size><width>375</width><height>667</height><depth>3</depth></size>
    <object>
        <name>Image</name>
        <bndbox><xmin>168</xmin><ymin>263</ymin><xmax>209</xmax><ymax>305</ymax></bndbox>
    </object>
</annotation>
"""


def test_map_drops_status_bar_and_unknown():
    boxes = [("UpperTaskBar", 0, 0, 375, 20), ("Drawer", 0, 0, 10, 10), ("TextButton", 10, 10, 50, 30)]
    assert map_and_filter(boxes) == [("button", 10, 10, 50, 30)]


def test_drop_nested_placeholder_text():
    boxes = [("textField", 0, 0, 100, 40), ("text", 5, 5, 60, 35), ("text", 0, 100, 50, 120)]
    assert drop_nested(boxes) == [("textField", 0, 0, 100, 40), ("text", 0, 100, 50, 120)]


def test_drop_nested_icon_in_button():
    assert drop_nested([("button", 0, 0, 100, 40), ("symbol", 4, 4, 30, 36)]) == [("button", 0, 0, 100, 40)]


def test_to_yolo_line():
    assert to_yolo_line(("button", 60, 485, 316, 500), 375, 667) == "1 0.501333 0.738381 0.682667 0.022489"


def test_split_is_70_15_15_and_stable():
    names = [f"f{i}" for i in range(100)]
    a, b = split(names), split(names)
    assert a == b and [len(a[k]) for k in ("train", "val", "test")] == [70, 15, 15]
    assert set(a["train"]) | set(a["val"]) | set(a["test"]) == set(names)


def test_parse_voc(tmp_path):
    xml = tmp_path / "wf_0.xml"
    xml.write_text(VOC_XML)
    assert parse_voc(xml) == (375, 667, [("Image", 168, 263, 209, 305)])
