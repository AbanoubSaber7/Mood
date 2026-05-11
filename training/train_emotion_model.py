#!/usr/bin/env python3
"""
Train a 7-class FER-style model for mood_app:
  - Input:  48 x 48 x 3 RGB, float (app divides pixels by 255 — match with Rescaling in graph or bake in).
  - Output: 7 logits (no softmax in exported TFLite) so the app can apply softmax and show %.

Place fer2013.csv in ./data/fer2013.csv (Kaggle: msambare/fer2013 or similar).
Columns: emotion, pixels, Usage — standard FER2013 CSV.

App label order (must match lib/screens/detection_screen.dart):
  0 Angry, 1 Disgust, 2 Fear, 3 Happy, 4 Neutral, 5 Sad, 6 Surprise

FER2013 emotion ids: 0 Angry, 1 Disgust, 2 Fear, 3 Happy, 4 Sad, 5 Surprise, 6 Neutral
"""

from __future__ import annotations

import argparse
import os
import sys

import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

# FER id -> app class index
FER_TO_APP = np.array([0, 1, 2, 3, 5, 6, 4], dtype=np.int64)


def load_fer_csv(csv_path: str) -> tuple[np.ndarray, np.ndarray]:
    df = pd.read_csv(csv_path)
    if "emotion" not in df.columns or "pixels" not in df.columns:
        raise ValueError("CSV needs 'emotion' and 'pixels' columns (standard fer2013.csv).")

    usage = df["Usage"].str.strip() if "Usage" in df.columns else None
    if usage is not None:
        df = df[usage == "Training"].reset_index(drop=True)

    n = len(df)
    x = np.zeros((n, 48, 48, 1), dtype=np.float32)
    y_app = np.zeros((n,), dtype=np.int64)

    pixels = df["pixels"].astype(str).str.split(expand=False).values
    emotions = df["emotion"].astype(np.int64).values

    for i in range(n):
        arr = np.array(pixels[i], dtype=np.float32).reshape(48, 48, 1)
        x[i] = arr
        e = int(emotions[i])
        if e < 0 or e > 6:
            raise ValueError(f"Invalid emotion id {e}")
        y_app[i] = FER_TO_APP[e]

    # Grayscale -> RGB (same three channels; matches app preprocessing)
    x = np.repeat(x / 255.0, 3, axis=-1)
    return x, y_app


def build_core() -> keras.Model:
    """Same input as the app: 48x48 RGB already scaled 0–1 in training data."""
    inputs = keras.Input(shape=(48, 48, 3))
    x = layers.Conv2D(32, 3, padding="same", activation="relu")(inputs)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D(2)(x)
    x = layers.Conv2D(64, 3, padding="same", activation="relu")(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D(2)(x)
    x = layers.Conv2D(128, 3, padding="same", activation="relu")(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D(2)(x)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.45)(x)
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.35)(x)
    outputs = layers.Dense(7, activation=None, dtype="float32")(x)
    return keras.Model(inputs, outputs, name="emotion_core")


def build_training_model(core: keras.Model) -> keras.Model:
    inputs = keras.Input(shape=(48, 48, 3))
    x = layers.RandomFlip("horizontal")(inputs)
    x = layers.RandomRotation(0.08)(x)
    x = layers.RandomZoom(0.1)(x)
    outputs = core(x)
    return keras.Model(inputs, outputs, name="emotion_train")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--data",
        default=os.path.join(os.path.dirname(__file__), "data", "fer2013.csv"),
        help="Path to fer2013.csv",
    )
    parser.add_argument(
        "--out",
        default=os.path.join(os.path.dirname(__file__), "output", "mood_emotion.tflite"),
        help="Output .tflite path",
    )
    parser.add_argument("--epochs", type=int, default=40)
    parser.add_argument("--batch", type=int, default=128)
    parser.add_argument("--lr", type=float, default=1e-3)
    args = parser.parse_args()

    if not os.path.isfile(args.data):
        print(
            "Missing dataset file:\n  ",
            args.data,
            "\n\nDownload FER-2013 (e.g. Kaggle msambare/fer2013), copy fer2013.csv into training/data/,\n"
            "then run:\n  pip install -r requirements.txt\n  python train_emotion_model.py",
            file=sys.stderr,
        )
        return 1

    x, y = load_fer_csv(args.data)
    y_cat = keras.utils.to_categorical(y, num_classes=7)

    n = len(x)
    idx = np.random.RandomState(42).permutation(n)
    split = int(0.9 * n)
    tr, va = idx[:split], idx[split:]

    core = build_core()
    model = build_training_model(core)
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=args.lr),
        loss=keras.losses.CategoricalCrossentropy(from_logits=True),
        metrics=["accuracy"],
    )

    early = keras.callbacks.EarlyStopping(
        monitor="val_accuracy", patience=6, restore_best_weights=True
    )
    reduce = keras.callbacks.ReduceLROnPlateau(
        monitor="val_loss", factor=0.5, patience=3, min_lr=1e-6
    )

    model.fit(
        x[tr],
        y_cat[tr],
        validation_data=(x[va], y_cat[va]),
        epochs=args.epochs,
        batch_size=args.batch,
        callbacks=[early, reduce],
        verbose=1,
    )

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    converter = tf.lite.TFLiteConverter.from_keras_model(core)
    tflite_bytes = converter.convert()
    with open(args.out, "wb") as f:
        f.write(tflite_bytes)

    print("Saved:", args.out)
    print(
        "Copy the file to assets/model/ and register it in pubspec.yaml;\n"
        "update Interpreter.fromAsset in detection_screen.dart if the filename differs."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
