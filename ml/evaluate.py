"""Eğitilmiş ağırlıkları değerlendirir ve sınıf başına markdown tablo basar.

Kullanım:
    .venv/bin/python evaluate.py runs/detect/vins/weights/best.pt --split test
"""
import argparse
from pathlib import Path

from ultralytics import YOLO

HERE = Path(__file__).resolve().parent


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("weights")
    parser.add_argument("--data", default=str(HERE / "vins.yaml"))
    parser.add_argument("--split", default="test")
    args = parser.parse_args()

    model = YOLO(args.weights)
    box = model.val(data=args.data, split=args.split, device="mps",
                    project=str(HERE / "runs" / "detect"), name="eval").box

    print("\n| class | precision | recall | mAP50 | mAP50-95 |")
    print("|---|---|---|---|---|")
    for i, c in enumerate(box.ap_class_index):
        p, r, ap50, ap = box.class_result(i)
        print(f"| {model.names[int(c)]} | {p:.3f} | {r:.3f} | {ap50:.3f} | {ap:.3f} |")
    print(f"| all | {box.mp:.3f} | {box.mr:.3f} | {box.map50:.3f} | {box.map:.3f} |")


if __name__ == "__main__":
    main()
