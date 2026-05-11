import 'package:flutter/material.dart';
import 'package:mood_app/widgets/background_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class StoriesScreen extends StatelessWidget {
  final String emotion;

  const StoriesScreen({super.key, required this.emotion});

  Color _getThemeColor(String e) {
    switch (e.toLowerCase()) {
      case 'happy':
        return Colors.amber.shade700;
      case 'sad':
        return Colors.blueGrey.shade600;
      case 'angry':
        return Colors.redAccent.shade200;
      case 'surprise':
        return Colors.orangeAccent.shade700;
      case 'fear':
        return Colors.deepPurple.shade300;
      case 'disgust':
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

  Widget _storyCard(
    BuildContext context,
    String title,
    String subtitle,
    String url,
    Color themeColor,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 380 + (index * 70)),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: Colors.white,
          elevation: 0,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () => _launchUrl(url),
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8E8ED)),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeColor.withValues(alpha: 0.45),
                          themeColor.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_rounded, color: themeColor, size: 30),
                        const SizedBox(height: 6),
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: themeColor.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 18, 14, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.45,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.auto_stories_outlined, size: 16, color: themeColor),
                              const SizedBox(width: 6),
                              Text(
                                'Read / Open Link',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: themeColor,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.north_east_rounded, color: themeColor.withValues(alpha: 0.5), size: 20),
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
        ),
      ),
    );
  }

  List<Map<String, String>> _getStoriesData(String e) {
    switch (e.toLowerCase()) {
      case 'sad':
        return [
          {'title': 'Overcoming Sadness', 'sub': 'Inspirational tips and stories to stay optimistic and move past hard moments.', 'url': 'https://en.wikipedia.org/wiki/Optimism'},
          {'title': 'Le Petit Prince', 'sub': 'A deep philosophical journey about love, friendship, and the meaning of life.', 'url': 'https://en.wikipedia.org/wiki/The_Little_Prince'},
          {'title': 'The Doors of Happiness', 'sub': 'How to find joy in the simplest details of your daily life.', 'url': 'https://en.wikipedia.org/wiki/Happiness'},
          {'title': 'The Light in the Dark', 'sub': 'A short story about finding hope when all seems lost.', 'url': 'https://americanliterature.com/short-stories'},
        ];
      case 'angry':
      case 'disgust':
        return [
          {'title': 'The Art of Calmness', 'sub': 'Your guide to reaching balance and controlling emotions.', 'url': 'https://en.wikipedia.org/wiki/Self-control'},
          {'title': 'The Metamorphosis', 'sub': 'Franz Kafka\'s novel, a journey into the depths of the psyche.', 'url': 'https://en.wikipedia.org/wiki/The_Metamorphosis'},
          {'title': 'The Power of Forgiveness', 'sub': 'How forgiveness frees you from the chains of anger and hatred.', 'url': 'https://en.wikipedia.org/wiki/Forgiveness'},
          {'title': 'The Art of Patience', 'sub': 'Learn how to remain calm under pressure.', 'url': 'https://americanliterature.com/short-stories'},
        ];
      case 'fear':
      case 'surprise':
        return [
          {'title': 'Facing the Unknown', 'sub': 'A story about true courage and how to overcome fears.', 'url': 'https://en.wikipedia.org/wiki/Courage'},
          {'title': 'The Brave Little Toaster', 'sub': 'An adventure story about courage and loyalty.', 'url': 'https://americanliterature.com/short-stories'},
          {'title': 'Journey to the Interior of the Earth', 'sub': 'A fictional adventure that takes you to amazing worlds.', 'url': 'https://en.wikipedia.org/wiki/Journey_to_the_Center_of_the_Earth'},
          {'title': 'Alice in Wonderland', 'sub': 'A classic journey into a world of wonders.', 'url': 'https://en.wikipedia.org/wiki/Alice%27s_Adventures_in_Wonderland'},
        ];
      case 'neutral':
        return [
          {'title': 'The Old Farmer\'s Wisdom', 'sub': 'Quiet life lessons inspired by nature and reality.', 'url': 'https://en.wikipedia.org/wiki/Wisdom'},
          {'title': 'The Alchemist', 'sub': 'Paulo Coelho\'s novel, follow your personal legend.', 'url': 'https://en.wikipedia.org/wiki/The_Alchemist_(novel)'},
          {'title': 'The Path of Quiet Success', 'sub': 'Simple steps to develop yourself away from the hustle of life.', 'url': 'https://en.wikipedia.org/wiki/Success'},
          {'title': 'Walden', 'sub': 'Reflections on living simply in natural surroundings.', 'url': 'https://en.wikipedia.org/wiki/Walden'},
        ];
      default:
        return [
          {'title': 'The Happy Surprise', 'sub': 'A cheerful story that spreads positivity and makes you see the bright side.', 'url': 'https://en.wikipedia.org/wiki/Joy'},
          {'title': 'The Gift of the Magi', 'sub': 'A heartwarming story about the spirit of giving.', 'url': 'https://en.wikipedia.org/wiki/The_Gift_of_the_Magi'},
          {'title': 'An Unforgettable Day', 'sub': 'Funny and beautiful situations that remind us of the beauty of life.', 'url': 'https://en.wikipedia.org/wiki/Laughter'},
          {'title': 'A Happy Life', 'sub': 'Inspirational short stories to keep your spirits high.', 'url': 'https://americanliterature.com/short-stories'},
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getThemeColor(emotion);
    final stories = _getStoriesData(emotion);
    final gradientColors = [
      themeColor.withValues(alpha: 0.95),
      themeColor.withValues(alpha: 0.6),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Stories'),
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
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stories Library',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                emotion,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Curated content to match your mood — tap to read in browser',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                    physics: const BouncingScrollPhysics(),
                    itemCount: stories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
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
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                      final i = index - 1;
                      return _storyCard(
                        context,
                        stories[i]['title']!,
                        stories[i]['sub']!,
                        stories[i]['url']!,
                        themeColor,
                        i,
                      );
                    },
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
