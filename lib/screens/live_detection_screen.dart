import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:mood_app/screens/recommendations_screen.dart';
import 'package:mood_app/services/emotion_tflite_helper.dart';
import 'package:mood_app/services/mood_alert_notification_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class LiveDetectionScreen extends StatefulWidget {
  final String userName;

  const LiveDetectionScreen({super.key, required this.userName});

  @override
  State<LiveDetectionScreen> createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen> {
  static const Duration _frameInterval = Duration(milliseconds: 1600);
  static const double _guideSizeRatio = 0.74;
  static const double _guideTopFactor = 0.24;

  CameraController? _camera;
  Interpreter? _interpreter;
  EmotionTfliteHelper? _helper;
  FaceDetector? _faceDetector;

  Timer? _timer;
  bool _busy = false;
  bool _modelReady = false;
  String? _liveEmotion;
  double? _liveConfidence;
  String? _cameraError;

  double? _faceLeftPct;
  double? _faceTopPct;
  double? _faceWidthPct;
  double? _faceHeightPct;
  // removed unused _faceAreaPct to clean analyzer warnings

  // alignment progress: increases when face is well-centered & big enough
  int _goodFrameCount = 0;
  // How many seconds the face must remain aligned before auto-capture
  double _requiredHoldSeconds = 5.0; // user requested longer hold (mutable)
  int get _requiredGoodFrames => math.max(
    1,
    (_requiredHoldSeconds * 1000 / _frameInterval.inMilliseconds).ceil(),
  );
  double _alignmentProgress = 0.0; // 0..1
  final double _requiredFaceAreaPct = 0.06; // 6% of image area
  final double _centerToleranceX = 0.20; // +/- 20% horizontally
  final double _centerToleranceY = 0.22; // +/- 22% vertically
  bool _autoCaptureTriggered = false;
  // recent live predictions aggregation to avoid noisy 'Neutral' outputs
  final List<EmotionPrediction> _recentPredictions = [];
  final int _aggregationCount = 3;

  static bool get _canUseMlKitFace =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _hasFaceBox =>
      _faceLeftPct != null &&
      _faceTopPct != null &&
      _faceWidthPct != null &&
      _faceHeightPct != null;

  @override
  void initState() {
    super.initState();
    if (_canUseMlKitFace) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        ),
      );
    }
    _loadModel();
    _loadHoldSecondsFromPrefs();
    _initCamera();
  }

  Future<void> _loadHoldSecondsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getDouble('live_hold_seconds');
      if (v != null && v >= 1.0 && v <= 10.0) {
        setState(() => _requiredHoldSeconds = v);
      }
    } catch (_) {}
  }

  Future<void> _saveHoldSecondsToPrefs(double v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('live_hold_seconds', v);
    } catch (_) {}
  }

  Future<void> _loadModel() async {
    try {
      final interpreter = await Interpreter.fromAsset(
        'assets/model/ferplus_model_pd_best.tflite',
      );
      if (!mounted) {
        interpreter.close();
        return;
      }
      _interpreter = interpreter;
      _helper = EmotionTfliteHelper(
        interpreter: interpreter,
        faceDetector: _faceDetector,
      );
      _helper!.refreshIoShapes();
      setState(() => _modelReady = true);
    } catch (e) {
      debugPrint('Live mode model load error: $e');
    }
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      setState(() => _cameraError = 'Live camera is not supported on the web.');
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera available.');
        return;
      }
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() => _camera = controller);
      _timer?.cancel();
      _timer = Timer.periodic(_frameInterval, (_) => _captureAndAnalyze());
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(
          () => _cameraError = 'Failed to start camera. Check permissions.',
        );
      }
    }
  }

  Future<void> _uploadSnapshot(
    String emotion,
    double confidence,
    File file,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !file.existsSync()) return;
    try {
      final fileName =
          'history/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mood_history')
          .add({
            'emotion': emotion,
            'confidence': confidence,
            'image_url': url,
            'timestamp': FieldValue.serverTimestamp(),
            'source': 'live',
          });
    } catch (e) {
      debugPrint('Live upload failed: $e');
    }
  }

  void _clearFaceBox() {
    if (!mounted) return;
    setState(() {
      _faceLeftPct = null;
      _faceTopPct = null;
      _faceWidthPct = null;
      _faceHeightPct = null;
    });
  }

  Future<void> _updateFaceBoxFromFile(File file) async {
    if (_faceDetector == null) return;
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        _clearFaceBox();
        return;
      }

      final box = faces.first.boundingBox;
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
        _clearFaceBox();
        return;
      }

      if (!mounted) return;
      // compute face metrics and alignment progress
      final leftPct = (box.left / decoded.width).clamp(0.0, 1.0);
      final topPct = (box.top / decoded.height).clamp(0.0, 1.0);
      final widthPct = (box.width / decoded.width).clamp(0.0, 1.0);
      final heightPct = (box.height / decoded.height).clamp(0.0, 1.0);
      final faceCenterX = leftPct + widthPct / 2.0;
      final faceCenterY = topPct + heightPct / 2.0;
      final faceAreaPct = (widthPct * heightPct).clamp(0.0, 1.0);

      // alignment criteria: centered and large enough
      final centered =
          (faceCenterX - 0.5).abs() <= _centerToleranceX &&
          (faceCenterY - 0.35).abs() <= _centerToleranceY;
      final largeEnough = faceAreaPct >= _requiredFaceAreaPct;
      final aligned = centered && largeEnough;

      if (aligned) {
        _goodFrameCount = (_goodFrameCount + 1).clamp(0, _requiredGoodFrames);
      } else {
        _goodFrameCount = 0;
        // reset auto-capture when user moves away
        _autoCaptureTriggered = false;
      }

      _alignmentProgress = (_goodFrameCount / _requiredGoodFrames).clamp(
        0.0,
        1.0,
      );

      // when alignment completes, give feedback, play sound and auto-capture once
      if (_alignmentProgress >= 1.0 && !_autoCaptureTriggered) {
        _autoCaptureTriggered = true;
        // feedback
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
        // schedule capture without awaiting (avoid reentrancy)
        if (!_busy && _camera != null && _camera!.value.isInitialized) {
          Future.microtask(() => _captureAndAnalyze());
        }
      }

      setState(() {
        _faceLeftPct = leftPct;
        _faceTopPct = topPct;
        _faceWidthPct = widthPct;
        _faceHeightPct = heightPct;
      });
    } catch (_) {}
  }

  Future<void> _captureAndAnalyze() async {
    if (_busy || !mounted || _camera == null || !_camera!.value.isInitialized)
      return;
    if (!_modelReady || _helper == null) return;
    if (_camera!.value.isTakingPicture) return;

    _busy = true;
    try {
      final xFile = await _camera!.takePicture();
      final file = File(xFile.path);

      await _updateFaceBoxFromFile(file);

      final pred = await _helper!.predictFromFile(file);
      if (!mounted || pred == null) return;

      // accumulate recent predictions
      _recentPredictions.add(pred);
      if (_recentPredictions.length < _aggregationCount) {
        // show interim live result but keep capturing
        setState(() {
          _liveEmotion = pred.emotion;
          _liveConfidence = pred.confidencePercent;
        });
        return; // wait for more frames
      }

      // we have enough predictions, aggregate using weighted confidence voting
      final Map<String, double> weightSum = {};
      final Map<String, List<double>> rawConfs = {};
      double totalWeight = 0.0;
      for (final p in _recentPredictions) {
        final label = p.emotion;
        // use confidence percent as weight; give a small boost to non-neutral labels
        final base = p.confidencePercent.clamp(0.0, 100.0);
        final weight = label.toLowerCase() == 'neutral' ? base : base * 1.05;
        weightSum[label] = (weightSum[label] ?? 0.0) + weight;
        rawConfs.putIfAbsent(label, () => []).add(p.confidencePercent);
        totalWeight += weight;
      }

      // pick winner by highest total weight
      String winner = weightSum.keys.first;
      double bestWeight = weightSum[winner]!;
      for (final k in weightSum.keys) {
        if (weightSum[k]! > bestWeight) {
          winner = k;
          bestWeight = weightSum[k]!;
        }
      }

      final avgOfWinner =
          (rawConfs[winner] ?? [0.0]).fold(0.0, (a, b) => a + b) /
          (rawConfs[winner]?.length ?? 1);
      final winnerShare = totalWeight > 0 ? bestWeight / totalWeight : 0.0;

      // Acceptance rule tuned to reduce spurious 'Neutral' results:
      // - Accept if winner holds >50% of weighted mass.
      // - If winner is non-neutral accept slightly easier (>40% share).
      // - If winner is Neutral, accept only if its average confidence is high (>=75%).
      final isNeutralWinner = winner.toLowerCase() == 'neutral';
      final acceptByShare =
          winnerShare > 0.5 || (!isNeutralWinner && winnerShare > 0.40);
      final acceptNeutralByConfidence = isNeutralWinner && avgOfWinner >= 75.0;

      if (acceptByShare || acceptNeutralByConfidence) {
        // accept and proceed
        _timer?.cancel();
        await MoodAlertNotificationService.instance.maybeAlertNegativeEmotion(
          winner,
          avgOfWinner,
        );
        await _uploadSnapshot(winner, avgOfWinner, file);

        if (!mounted) return;
        setState(() {
          _liveEmotion = winner;
          _liveConfidence = avgOfWinner;
        });

        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RecommendationsScreen(
              userName: widget.userName,
              emotion: winner,
              confidencePercent: avgOfWinner,
              source: 'model',
            ),
          ),
        );
      } else {
        // not confident yet; reset recent predictions and continue capturing
        _recentPredictions.clear();
        setState(() {
          _liveEmotion = 'Neutral';
          _liveConfidence = null;
        });
        return;
      }
    } catch (e) {
      debugPrint('Live frame error: $e');
      if (mounted &&
          _camera != null &&
          _camera!.value.isInitialized &&
          _timer == null) {
        _timer = Timer.periodic(_frameInterval, (_) => _captureAndAnalyze());
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _camera?.dispose();
    _faceDetector?.close();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Camera'),
        backgroundColor: const Color(0xFFC05A4E),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              // open bottom sheet with slider
              showModalBottomSheet(
                context: context,
                builder: (ctx) {
                  double tmp = _requiredHoldSeconds;
                  return StatefulBuilder(
                    builder: (c, setC) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Auto-capture hold time (seconds)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              min: 1.0,
                              max: 10.0,
                              divisions: 9,
                              value: tmp,
                              label: tmp.toStringAsFixed(0),
                              onChanged: (v) => setC(() => tmp = v),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Hold: ${tmp.toStringAsFixed(0)}s'),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    setState(() => _requiredHoldSeconds = tmp);
                                    _saveHoldSecondsToPrefs(tmp);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Saved hold time: ${tmp.toStringAsFixed(0)}s',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _cameraError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_cameraError!, textAlign: TextAlign.center),
              ),
            )
          : _camera == null || !_camera!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_camera!),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final pw = constraints.maxWidth;
                    final ph = constraints.maxHeight;
                    final guideSize = pw * _guideSizeRatio;
                    final guideLeft = (pw - guideSize) / 2;
                    final guideTop = (ph - guideSize) * _guideTopFactor;
                    final guideRect = Rect.fromLTWH(
                      guideLeft,
                      guideTop,
                      guideSize,
                      guideSize,
                    );

                    Rect? faceRect;
                    bool isFaceInsideGuide = false;
                    if (_hasFaceBox) {
                      final left = _faceLeftPct!.clamp(0.0, 1.0) * pw;
                      final top = _faceTopPct!.clamp(0.0, 1.0) * ph;
                      final width = _faceWidthPct!.clamp(0.0, 1.0) * pw;
                      final height = _faceHeightPct!.clamp(0.0, 1.0) * ph;
                      faceRect = Rect.fromLTWH(left, top, width, height);
                      isFaceInsideGuide =
                          guideRect.contains(faceRect.topLeft) &&
                          guideRect.contains(faceRect.bottomRight);
                    }

                    // guide color blends from white -> red -> green based on alignment
                    final baseColor = !_hasFaceBox
                        ? Colors.white70
                        : (isFaceInsideGuide
                              ? Colors.greenAccent
                              : Colors.redAccent);
                    // smooth color by alignment progress (green when aligned)
                    final guideColor = Color.lerp(
                      Colors.white70,
                      baseColor,
                      _alignmentProgress,
                    )!;
                    final statusText = !_hasFaceBox
                        ? 'Align your face inside the frame'
                        : (isFaceInsideGuide
                              ? 'Good position — hold still'
                              : 'Move face inside the frame');

                    return Stack(
                      children: [
                        Positioned(
                          left: guideLeft,
                          top: guideTop,
                          width: guideSize,
                          height: guideSize,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: guideColor,
                                  width: 2.6,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        // small circular progress near the guide (top-right)
                        Positioned(
                          left: guideLeft + guideSize - 56,
                          top: guideTop - 12,
                          width: 56,
                          height: 56,
                          child: IgnorePointer(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: CircularProgressIndicator(
                                    value: _alignmentProgress,
                                    color: guideColor,
                                    backgroundColor: Colors.white12,
                                    strokeWidth: 4,
                                  ),
                                ),
                                Text(
                                  '${(_alignmentProgress * 100).toInt()}%',
                                  style: TextStyle(
                                    color: guideColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (faceRect != null)
                          Positioned(
                            left: faceRect.left,
                            top: faceRect.top,
                            width: faceRect.width,
                            height: faceRect.height,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: guideColor,
                                    width: 2.5,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: guideColor.withOpacity(0.14),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 52,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              // slightly stronger background to ensure readability
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: guideColor, width: 1.2),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.black54,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_modelReady)
                          const Text(
                            'Loading model...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (_liveEmotion == null)
                          Text(
                            'Face the camera - automatic analysis every ~${(_frameInterval.inMilliseconds / 1000).toStringAsFixed(1)} s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else ...[
                          const Text(
                            'Result',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_liveEmotion ?? 'Unknown'}' +
                                (_liveConfidence != null
                                    ? '  •  ${_liveConfidence!.toStringAsFixed(0)}%'
                                    : ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Opening recommendations...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
