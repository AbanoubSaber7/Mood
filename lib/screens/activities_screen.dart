import 'package:flutter/material.dart';
import '../widgets/background_widget.dart'; // ده المسار لملف الخلفية اللي أنت فاتحه في الصورة

class ActivitiesScreen extends StatelessWidget {
  final String emotion;
  const ActivitiesScreen({Key? key, required this.emotion}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Activities based on mood
    Map<String, List<String>> activities = {
      'happy': ['Share your joy with a friend', 'Capture your happy moment with a photo', 'Go for a walk'],
      'sad': ['Write 3 things you are grateful for', 'Listen to calm music', 'Talk to someone you trust'],
      'angry': ['Breathing exercises (Inhale & Exhale)', 'Do some physical exercise', 'Count from 1 to 100'],
      'fear': ['5-4-3-2-1 Grounding Technique', 'Listen to nature sounds', 'Remind yourself that you are safe'],
      'neutral': ['Plan your upcoming tasks', 'Read an interesting article', 'Organize your room or office'],
    };

    List<String> currentActivities = activities[emotion.toLowerCase()] ?? ['Relax for a bit'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: BackgroundWidget(
        emotion: emotion,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Since you feel $emotion",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ...currentActivities.map((activity) => Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white.withOpacity(0.2),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.white),
                  title: Text(activity, style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}