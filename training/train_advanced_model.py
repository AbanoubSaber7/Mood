#!/usr/bin/env python3
"""
High-Accuracy Emotion Detection Model using MobileNetV2
For the 'Mood-main' App.

This script will:
1. Load fer2013.csv (48x48 images).
2. Upscale images to 96x96 RGB so MobileNetV2 can extract high-quality features.
3. Map labels to EXACTLY match what `emotion_tflite_helper.dart` expects:
   0:Neutral, 1:Happy, 2:Surprise, 3:Sad, 4:Angry, 5:Disgust, 6:Fear
4. Train with aggressive data augmentation.
5. Save to `vgg16_emotion_model.tflite`.
"""

import argparse
import os
import sys
import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
# pyrefly: ignore [missing-import]
from tensorflow.keras.applications import VGG16

# FER2013 classes: 0=Angry, 1=Disgust, 2=Fear, 3=Happy, 4=Sad, 5=Surprise, 6=Neutral
# APP classes: 0=Neutral, 1=Happy, 2=Surprise, 3=Sad, 4=Angry, 5=Disgust, 6=Fear
# Mapping array: index is FER id, value is APP id
FER_TO_APP = np.array([4, 5, 6, 1, 3, 2, 0], dtype=np.int64)

IMG_SIZE = 96
NUM_CLASSES = 7

def load_fer_csv(csv_path: str) -> tuple[np.ndarray, np.ndarray]:
    df = pd.read_csv(csv_path)
    if "emotion" not in df.columns or "pixels" not in df.columns:
        raise ValueError("CSV needs 'emotion' and 'pixels' columns (standard fer2013.csv).")

    usage = df["Usage"].str.strip() if "Usage" in df.columns else None
    if usage is not None:
        # To train faster, we can use the whole dataset or just Training
        df = df[usage == "Training"].reset_index(drop=True)

    n = len(df)
    # We will load as 48x48 first, then resize later using tf.image.resize
    x = np.zeros((n, 48, 48, 1), dtype=np.float32)
    y_app = np.zeros((n,), dtype=np.int64)

    pixels = df["pixels"].astype(str).str.split(expand=False).values
    emotions = df["emotion"].astype(np.int64).values

    for i in range(n):
        arr = np.array(pixels[i], dtype=np.float32).reshape(48, 48, 1)
        x[i] = arr
        e = int(emotions[i])
        if e < 0 or e > 6:
            continue
        y_app[i] = FER_TO_APP[e]

    # Convert Grayscale to RGB
    x = np.repeat(x, 3, axis=-1)
    
    # We resize immediately using TF to save time during training
    print("Resizing images to 96x96 for VGG16. This may take a moment...")
    x = tf.image.resize(x, [IMG_SIZE, IMG_SIZE]).numpy()
    
    # Normalize to 0-1
    x = x / 255.0
    return x, y_app

def build_vgg16_model() -> keras.Model:
    inputs = keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
    
    # Data Augmentation layer directly in the model
    x = layers.RandomFlip("horizontal")(inputs)
    x = layers.RandomRotation(0.1)(x)
    x = layers.RandomZoom(0.1)(x)
    
    # Load VGG16
    base_model = VGG16(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,
        weights='imagenet'
    )
    # Freeze base model initially for stable transfer learning
    base_model.trainable = False
    
    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.5)(x)
    # Output layer: 7 classes
    outputs = layers.Dense(NUM_CLASSES, activation=None, dtype="float32")(x)
    
    return keras.Model(inputs, outputs, name="vgg16_emotion_model")

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--data",
        default=os.path.join(os.path.dirname(__file__), "data", "fer2013.csv"),
        help="Path to fer2013.csv",
    )
    parser.add_argument(
        "--out",
        default=os.path.join(os.path.dirname(__file__), "output", "vgg16_emotion_model.tflite"),
        help="Output .tflite path",
    )
    parser.add_argument("--epochs", type=int, default=20)
    parser.add_argument("--batch", type=int, default=64)
    parser.add_argument("--lr", type=float, default=1e-3)
    args = parser.parse_args()

    if not os.path.isfile(args.data):
        print(f"Missing dataset file: {args.data}\nPlease put fer2013.csv inside the training/data/ folder.")
        return 1

    print("Loading Dataset...")
    x, y = load_fer_csv(args.data)
    y_cat = keras.utils.to_categorical(y, num_classes=NUM_CLASSES)

    n = len(x)
    idx = np.random.RandomState(42).permutation(n)
    split = int(0.9 * n)
    tr, va = idx[:split], idx[split:]

    print("Building VGG16 Model...")
    model = build_vgg16_model()
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=args.lr),
        loss=keras.losses.CategoricalCrossentropy(from_logits=True),
        metrics=["accuracy"],
    )

    early = keras.callbacks.EarlyStopping(monitor="val_accuracy", patience=5, restore_best_weights=True)
    reduce = keras.callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=2, min_lr=1e-6)

    print("Training Model...")
    model.fit(
        x[tr], y_cat[tr],
        validation_data=(x[va], y_cat[va]),
        epochs=args.epochs,
        batch_size=args.batch,
        callbacks=[early, reduce],
        verbose=1,
    )

    print("Fine-tuning Model (Unfreezing layers)...")
    # Unfreeze and fine-tune for extra accuracy
    model.layers[4].trainable = True # Unfreeze VGG16 base
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-5), # Tiny learning rate
        loss=keras.losses.CategoricalCrossentropy(from_logits=True),
        metrics=["accuracy"],
    )
    model.fit(
        x[tr], y_cat[tr],
        validation_data=(x[va], y_cat[va]),
        epochs=10,
        batch_size=args.batch,
        callbacks=[early],
        verbose=1,
    )

    # Convert to TFLite
    print(f"Converting and saving to {args.out}...")
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    
    # We must convert the model that takes inputs and outputs logits
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_bytes = converter.convert()
    
    with open(args.out, "wb") as f:
        f.write(tflite_bytes)

    print("Done! You can now use advanced_emotion_model.tflite in your Flutter app.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
