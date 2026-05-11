import 'package:flutter/material.dart';
import 'package:mood_app/widgets/background_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class VideosScreen extends StatelessWidget {
  final String emotion;

  const VideosScreen({super.key, required this.emotion});

  Color _themeColor(String e) {
    switch (e.toLowerCase()) {
      case 'happy':
        return Colors.amber.shade700;
      case 'sad':
        return Colors.blueGrey.shade600;
      case 'angry':
      case 'disgust':
        return Colors.redAccent.shade200;
      case 'surprise':
        return Colors.orangeAccent.shade700;
      case 'fear':
        return Colors.deepPurple.shade300;
      case 'neutral':
      default:
        return const Color(0xFFC05A4E);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Widget _videoCard(String title, String url, Color accent, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE8E8ED)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFFF0000).withValues(alpha: 0.85),
                              accent.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GridNoisePainter(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              const Text(
                                'YouTube',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.25,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.touch_app_outlined, size: 14, color: accent),
                          const SizedBox(width: 6),
                          Text(
                            'Open Search',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _items(Color accent) {
    IconData ic = Icons.video_library_rounded;
    switch (emotion.toLowerCase()) {
      case 'sad':
        return [
          _videoCard('Very Funny Clips', 'https://www.youtube.com/results?search_query=funny+videos+2026', accent, ic),
          _videoCard('Stand-up Comedy', 'https://www.youtube.com/results?search_query=stand+up+comedy+arabic', accent, ic),
          _videoCard('Study & Work Motivation', 'https://www.youtube.com/results?search_query=motivational+videos+arabic', accent, ic),
          _videoCard('Cute Puppies', 'https://www.youtube.com/results?search_query=cute+puppies+compilation', accent, ic),
          _videoCard('Funny National Geographic', 'https://www.youtube.com/results?search_query=funny+animals+national+geographic', accent, ic),
          _videoCard('Life Hacks', 'https://www.youtube.com/results?search_query=amazing+life+hacks', accent, ic),
        ];
      case 'angry':
        return [
          _videoCard('Deep Breathing Exercises', 'https://www.youtube.com/results?search_query=deep+breathing+exercises', accent, ic),
          _videoCard('ASMR Satisfying', 'https://www.youtube.com/results?search_query=satisfying+video+asmr', accent, ic),
          _videoCard('Calm Music for Nerves', 'https://www.youtube.com/results?search_query=calm+music+for+anger', accent, ic),
          _videoCard('Yoga for Beginners', 'https://www.youtube.com/results?search_query=yoga+for+relaxation', accent, ic),
          _videoCard('Nature Scenery 4K', 'https://www.youtube.com/results?search_query=nature+4k+relax', accent, ic),
          _videoCard('Optimism Stories', 'https://www.youtube.com/results?search_query=inspiring+short+stories', accent, ic),
        ];
      case 'fear':
      case 'disgust':
        return [
          _videoCard('Overcoming Anxiety Tips', 'https://www.youtube.com/results?search_query=overcoming+anxiety+tips', accent, ic),
          _videoCard('Guided Meditation', 'https://www.youtube.com/results?search_query=meditation+for+fear', accent, ic),
          _videoCard('Fun Challenges', 'https://www.youtube.com/results?search_query=fun+challenges+videos', accent, ic),
          _videoCard('Beautiful Cities', 'https://www.youtube.com/results?search_query=beautiful+cities+walkthrough', accent, ic),
          _videoCard('Positive Affirmations', 'https://www.youtube.com/results?search_query=positive+affirmations+arabic', accent, ic),
          _videoCard('Manual Creativity', 'https://www.youtube.com/results?search_query=creative+art+process', accent, ic),
        ];
      case 'neutral':
        return [
          _videoCard('Short Documentary', 'https://www.youtube.com/results?search_query=short+documentary+interesting', accent, ic),
          _videoCard('Tech Reviews', 'https://www.youtube.com/results?search_query=latest+tech+gadgets+2026', accent, ic),
          _videoCard('Learn a New Skill', 'https://www.youtube.com/results?search_query=learn+new+skill+in+5+minutes', accent, ic),
          _videoCard('Space Exploration', 'https://www.youtube.com/results?search_query=space+and+planets+discovery', accent, ic),
          _videoCard('Inspiring Podcast', 'https://www.youtube.com/results?search_query=inspiring+podcast+arabic', accent, ic),
          _videoCard('Top 10 Facts', 'https://www.youtube.com/results?search_query=top+10+interesting+facts', accent, ic),
        ];
      case 'surprise':
        return [
          _videoCard('Amazing Magic Tricks', 'https://www.youtube.com/results?search_query=amazing+magic+tricks+revealed', accent, ic),
          _videoCard('Sci-Fi Concept Art', 'https://www.youtube.com/results?search_query=future+technology+concepts', accent, ic),
          _videoCard('Reaction Videos', 'https://www.youtube.com/results?search_query=funny+reaction+videos', accent, ic),
          _videoCard('Science Experiments', 'https://www.youtube.com/results?search_query=cool+science+experiments', accent, ic),
          _videoCard('Strangest Places in the World', 'https://www.youtube.com/results?search_query=strangest+places+on+earth', accent, ic),
          _videoCard('Optical Illusions', 'https://www.youtube.com/results?search_query=best+optical+illusions', accent, ic),
        ];
      case 'happy':
      default:
        return [
          _videoCard('Upbeat Songs', 'https://www.youtube.com/results?search_query=happy+upbeat+songs', accent, ic),
          _videoCard('Celebration Moments', 'https://www.youtube.com/results?search_query=best+celebration+moments', accent, ic),
          _videoCard('Funny Pranks', 'https://www.youtube.com/results?search_query=funny+pranks+clean', accent, ic),
          _videoCard('Travel Vlogs', 'https://www.youtube.com/results?search_query=fun+travel+vlogs', accent, ic),
          _videoCard('Kids Playing', 'https://www.youtube.com/results?search_query=kids+funny+moments', accent, ic),
          _videoCard('Fun Daily Vlogs', 'https://www.youtube.com/results?search_query=daily+vlogs+fun', accent, ic),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _themeColor(emotion);
    final gradientColors = [
      accent.withValues(alpha: 0.95),
      accent.withValues(alpha: 0.6),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Videos'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BackgroundWidget(
        emotion: emotion,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Videos',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            emotion,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap on the card to open YouTube search results',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.72,
                            physics: const BouncingScrollPhysics(),
                            children: _items(accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridNoisePainter extends CustomPainter {
  _GridNoisePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 18.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
