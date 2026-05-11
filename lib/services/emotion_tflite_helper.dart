import 'dart:io';
import 'dart:math' as math;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class EmotionPrediction {
  const EmotionPrediction({
    required this.emotion,
    required this.confidencePercent,
  });
  final String emotion;
  final double confidencePercent;
}

class EmotionTfliteHelper {
  EmotionTfliteHelper({required this.interpreter, this.faceDetector});

  final Interpreter interpreter;
  final FaceDetector? faceDetector;

  static const List<String> emotionLabels = [
    'Neutral',
    'Happy',
    'Surprise',
    'Sad',
    'Angry',
    'Disgust',
    'Fear',
 
  ];

  int numClasses = 8;
  int inputChannels = 1;
  int inputSize = 48;

  void refreshIoShapes() {
    final inShape = interpreter.getInputTensor(0).shape;
    final outShape = interpreter.getOutputTensor(0).shape;
    inputChannels = inShape.last;
    if (inShape.length >= 3) inputSize = inShape[1];
    if (outShape.length >= 2) numClasses = outShape[1];
  }

  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return [];
    final m = logits.reduce(math.max);
    var sum = 0.0;
    final exps = <double>[];
    for (final x in logits) {
      final e = math.exp(x - m);
      exps.add(e);
      sum += e;
    }
    if (sum <= 0) return List.filled(logits.length, 1.0 / logits.length);
    return exps.map((e) => e / sum).toList();
  }

  List<double> _rawScoresToProbabilities(List<double> raw) {
    if (raw.isEmpty) return raw;
    final sum = raw.fold<double>(0, (a, b) => a + b);
    if (raw.every((v) => v >= -1e-6) && sum > 0.9 && sum < 1.1) {
      return raw.map((v) => v.clamp(0.0, 1.0)).toList();
    }
    return _softmax(raw);
  }

  Future<List<dynamic>> preprocessImageFile(File file) async {
    // Read bytes asynchronously to avoid blocking the UI thread.
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return [];

    img.Image region = image;
    if (faceDetector != null) {
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await faceDetector!.processImage(inputImage);
      if (faces.isNotEmpty) {
        // Use the first detected face. Expand the box slightly to include context.
        final box = faces.first.boundingBox;
        // Add small padding (20%) around the face box.
        final padW = (box.width * 0.2).toInt();
        final padH = (box.height * 0.2).toInt();

        var x = (box.left.toInt() - padW).clamp(0, image.width - 1);
        var y = (box.top.toInt() - padH).clamp(0, image.height - 1);
        var w = (box.width.toInt() + padW * 2);
        var h = (box.height.toInt() + padH * 2);

        // Ensure width/height do not overflow image bounds
        if (x + w > image.width) w = image.width - x;
        if (y + h > image.height) h = image.height - y;

        // If computed box is invalid, fallback to whole image
        if (w > 0 && h > 0) {
          region = img.copyCrop(image, x: x, y: y, width: w, height: h);
        }
      } else {
        // No faces found - treat this as a validation failure when a face detector
        // is available. Return an empty input so callers know there's no face.
        return [];
      }
    } else {
      // No face detector - center-crop to square
      final shortSide = math.min(image.width, image.height);
      final cx = (image.width - shortSide) ~/ 2;
      final cy = (image.height - shortSide) ~/ 2;
      region = img.copyCrop(
        image,
        x: cx,
        y: cy,
        width: shortSide,
        height: shortSide,
      );
    }

    // Resize to the model expected input size (dynamic).
    final resized = img.copyResize(region, width: inputSize, height: inputSize);
    // Prepare the input tensor as nested Lists (batch, h, w, channels).
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (_) => List.generate(inputSize, (_) => List.filled(inputChannels, 0.0)),
      ),
    );

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        final double luminance =
            (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).toDouble();
        if (inputChannels == 1) {
          // Normalize to 0..1 floats
          input[0][y][x][0] = luminance / 255.0;
        } else {
          input[0][y][x][0] = (pixel.r / 255.0);
          input[0][y][x][1] = (pixel.g / 255.0);
          input[0][y][x][2] = (pixel.b / 255.0);
        }
      }
    }
    return input;
  }

  EmotionPrediction predictFromInput(List<dynamic> input) {
    final output = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);
    interpreter.run(input, output);
    final raw = List<double>.generate(
      numClasses,
      (i) => (output[0][i] as num).toDouble(),
    );
    final probs = _rawScoresToProbabilities(raw);
    var index = 0;
    var bestP = probs[0];
    for (int i = 1; i < numClasses; i++) {
      if (probs[i] > bestP) {
        bestP = probs[i];
        index = i;
      }
    }
    return EmotionPrediction(
      emotion: emotionLabels[index],
      confidencePercent: (bestP * 100).clamp(0.0, 100.0),
    );
  }

  Future<EmotionPrediction?> predictFromFile(File file) async {
    final input = await preprocessImageFile(file);
    if (input.isEmpty) return null;
    return predictFromInput(input);
  }
}
