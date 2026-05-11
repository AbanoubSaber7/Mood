import 'dart:io';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_app/widgets/background_widget.dart';
import 'package:mood_app/screens/recommendations_screen.dart';
import 'package:mood_app/screens/live_detection_screen.dart';
import 'package:mood_app/screens/mood_history_screen.dart';
import 'package:mood_app/services/emotion_tflite_helper.dart';
import 'package:mood_app/services/mood_alert_notification_service.dart';

class DetectionScreen extends StatefulWidget {
  final String userName;
  const DetectionScreen({Key? key, required this.userName}) : super(key: key);

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  File? _pickedFile;
  String? predictedEmotion;
  double? predictedConfidencePercent;
  String? manualSelectedEmotion;
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();
  Interpreter? _interpreter;
  FaceDetector? _faceDetector;
  EmotionTfliteHelper? _emotionHelper;

  Color _getThemeColor(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happy':
        return Colors.amber;
      case 'sad':
        return Colors.blueGrey;
      case 'angry':
        return Colors.redAccent;
      case 'surprise':
        return Colors.orangeAccent;
      case 'fear':
        return Colors.deepPurple;
      case 'disgust':
        return const Color.fromARGB(255, 174, 79, 146);
      case 'neutral':
      default:
        return const Color(0xFFC05A4E);
    }
  }

  @override
  void initState() {
    super.initState();
    if (_canUseMlKitFace) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          minFaceSize: 0.12,
        ),
      );
    }
    loadModel();
  }

  static bool get _canUseMlKitFace =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void dispose() {
    _faceDetector?.close();
    _interpreter?.close();
    super.dispose();
  }

  void _syncEmotionHelper() {
    if (_interpreter == null) {
      _emotionHelper = null;
      return;
    }
    _emotionHelper = EmotionTfliteHelper(
      interpreter: _interpreter!,
      faceDetector: _faceDetector,
    );
    _emotionHelper!.refreshIoShapes();
  }

  Future<void> loadModel() async {
    const assetPath = 'assets/model/ferplus_model_pd_best.tflite';
    try {
      _interpreter = await Interpreter.fromAsset(assetPath);
      _syncEmotionHelper();
    } catch (e) {
      debugPrint('Error loading TFLite: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _pickedFile = File(image.path);
        manualSelectedEmotion = null;
        predictedEmotion = null;
        predictedConfidencePercent = null;
      });
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
              child: Text(
                "Select Image Source",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: _getThemeColor(
                  predictedEmotion ?? manualSelectedEmotion,
                ),
              ),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: _getThemeColor(
                  predictedEmotion ?? manualSelectedEmotion,
                ),
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _predictFromModel() async {
    if (_emotionHelper == null || _pickedFile == null) return;
    setState(() => isLoading = true);

    try {
      final prediction = await _emotionHelper!.predictFromFile(_pickedFile!);
      if (prediction == null) {
        setState(() => isLoading = false);
        // No face found / validation failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please upload an image that contains a human face.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final result = prediction.emotion;
      final confidencePct = prediction.confidencePercent;

      await MoodAlertNotificationService.instance.maybeAlertNegativeEmotion(
        result,
        confidencePct,
      );
      await _uploadImageAndSaveRecord(result, confidencePct);

      setState(() {
        predictedEmotion = result;
        predictedConfidencePercent = confidencePct;
        isLoading = false;
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        _navigateToRecommendations(
          result,
          confidencePercent: confidencePct,
          source: 'model',
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _uploadImageAndSaveRecord(
    String emotion,
    double confidence,
  ) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _pickedFile == null) return;
    try {
      String fileName =
          'history/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      await storageRef.putFile(_pickedFile!);
      String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mood_history')
          .add({
            'emotion': emotion,
            'confidence': confidence,
            'image_url': downloadUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Upload failed: $e");
    }
  }

  Future<void> _handleNavigation() async {
    if (manualSelectedEmotion != null && _pickedFile == null) {
      _navigateToRecommendations(manualSelectedEmotion!, source: 'manual');
      return;
    }
    if (_pickedFile != null) {
      await _predictFromModel();
    }
  }

  void _navigateToRecommendations(
    String finalEmotion, {
    double? confidencePercent,
    String source = 'model',
  }) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationsScreen(
          userName: widget.userName,
          emotion: finalEmotion,
          confidencePercent: confidencePercent,
          source: source,
        ),
      ),
    );
  }

  Future<void> handleLogout() async {
    // Sign out from Firebase (if signed in) and clear local auth metadata only.
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // ignore
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final wasGuest = prefs.getBool('isGuest') ?? false;
    await prefs.remove('user_name');
    await prefs.remove('isLoggedIn');
    await prefs.remove('isGuest');
    await prefs.remove('user_id');
    if (wasGuest) {
      // if it was a guest session and you want to clear anon history on logout,
      // remove anon key. Comment out if you prefer to keep guest history.
      await prefs.remove('mood_history_entries_v1_anon');
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _openLiveMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveDetectionScreen(userName: widget.userName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEmotion = predictedEmotion ?? manualSelectedEmotion;
    final themeColor = _getThemeColor(currentEmotion);

    const appBarForeground = Color(0xFF1C1C1E);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Mood Detection',
          style: TextStyle(
            color: appBarForeground,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.92),
        foregroundColor: appBarForeground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black26,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: appBarForeground, size: 24),
        actionsIconTheme: const IconThemeData(
          color: appBarForeground,
          size: 24,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  tooltip: 'Mood history',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MoodHistoryScreen(userName: widget.userName),
                      ),
                    );
                  },
                ),
                Container(height: 28, width: 1, color: Colors.grey.shade300),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  tooltip: 'Live Camera',
                  onPressed: kIsWeb ? null : _openLiveMode,
                ),
                Container(height: 28, width: 1, color: Colors.grey.shade300),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
      body: BackgroundWidget(
        emotion: currentEmotion ?? 'Neutral',
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeColor.withOpacity(0.8),
                Colors.white.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Welcome, ${widget.userName}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'How are you feeling?',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  if (kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Live camera is available on Android and iOS only.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 30),
                  _buildImagePickerArea(themeColor),
                  const SizedBox(height: 25),
                  const Text(
                    "OR",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildManualDropdown(themeColor),
                  const SizedBox(height: 40),
                  _buildPredictButton(themeColor),
                  if (predictedEmotion != null) _buildResultCard(themeColor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerArea(Color themeColor) {
    return GestureDetector(
      onTap: _showPickerOptions,
      child: Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: _pickedFile != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_pickedFile!, fit: BoxFit.cover),
                    Container(
                      color: Colors.black38,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 40),
                            SizedBox(height: 8),
                            Text(
                              "Change Photo",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 70,
                      color: themeColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Tap to upload or take photo",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildManualDropdown(Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: manualSelectedEmotion,
          hint: const Text("Select Mood Manually"),
          isExpanded: true,
          items: EmotionTfliteHelper.emotionLabels
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) => setState(() {
            manualSelectedEmotion = v;
            _pickedFile = null;
            predictedEmotion = null;
          }),
        ),
      ),
    );
  }

  Widget _buildPredictButton(Color themeColor) {
    bool canAction =
        (_pickedFile != null || manualSelectedEmotion != null) && !isLoading;
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: canAction ? _handleNavigation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: canAction ? 5 : 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _pickedFile != null ? 'ANALYZE MOOD' : 'CONTINUE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: canAction ? Colors.white : Colors.grey.shade600,
                ),
              ),
      ),
    );
  }

  Widget _buildResultCard(Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            predictedEmotion!,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
          Text(
            'Confidence: ${predictedConfidencePercent!.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
