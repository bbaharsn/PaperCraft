"""YOLO11n modelini VINS verisiyle eğitir.

Kullanım:
    .venv/bin/python train.py          # tam eğitim (50 epoch)
    .venv/bin/python train.py --smoke  # hızlı deneme (1 epoch, verinin %5'i)
"""
import argparse
from pathlib import Path

from ultralytics import YOLO

HERE = Path(__file__).resolve().parent

AUGMENT = dict(fliplr=0.0, perspective=0.0005, hsv_v=0.4, hsv_s=0.5, degrees=2)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--smoke", action="store_true", help="1 epoch, verinin %%5'i")
    args = parser.parse_args()

    model = YOLO("yolo11n.pt")
    common = dict(
        data=str(HERE / "vins.yaml"),
        imgsz=640,
        device="mps",
        project=str(HERE / "runs" / "detect"),
        **AUGMENT,
    )
    if args.smoke:
        model.train(epochs=1, fraction=0.05, name="vins-smoke", **common)
    else:
        model.train(epochs=50, patience=10, name="vins", **common)


if __name__ == "__main__":
    main()
