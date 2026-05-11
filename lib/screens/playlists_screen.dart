import 'package:flutter/material.dart';
import 'package:mood_app/widgets/background_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaylistsScreen extends StatelessWidget {
  final String emotion;

  const PlaylistsScreen({super.key, required this.emotion});

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

  Widget _sectionHeader(BuildContext context, String title, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: const Color(0xFF1C1C1E),
                ),
          ),
        ],
      ),
    );
  }

  Widget _trackTile(String title, String artist, String url, Color accent, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        shadowColor: accent.withValues(alpha: 0.12),
        child: InkWell(
          onTap: () => _launchUrl(url),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8E8ED)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.35),
                          accent.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                    child: Icon(Icons.music_note_rounded, color: accent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.25,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: accent, size: 26),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, Color accent) {
    switch (emotion.toLowerCase()) {
      case 'sad':
        return [
          _sectionHeader(context, 'Arabic Classics', accent),
          _trackTile('Ana Mosamam', 'Bahaa Sultan', 'https://open.spotify.com/search/Ana%20Mosamam%20Bahaa%20Sultan', accent, 0),
          _trackTile('Kalam Einieh', 'Sherine', 'https://open.spotify.com/search/Kalam%20Einieh%20Sherine', accent, 1),
          _trackTile('Aks Elli Shayfenha', 'Elissa', 'https://open.spotify.com/search/Aks%20Elli%20Shayfenha', accent, 2),
          _trackTile('Tansa Ka Anak Lam Takon', 'Cairokee', 'https://open.spotify.com/search/Cairokee%20Tansa', accent, 3),
          _sectionHeader(context, 'International Melancholy', accent),
          _trackTile('Someone Like You', 'Adele', 'https://open.spotify.com/search/Adele%20Someone%20Like%20You', accent, 4),
          _trackTile('Fix You', 'Coldplay', 'https://open.spotify.com/search/Coldplay%20Fix%20You', accent, 5),
          _trackTile('Lose You To Love Me', 'Selena Gomez', 'https://open.spotify.com/search/Selena%20Lose%20You%20To%20Love%20Me', accent, 6),
        ];
      case 'angry':
      case 'disgust':
        return [
          _sectionHeader(context, 'Calm & Peace', accent),
          _trackTile('Tamally Maak', 'Amr Diab', 'https://open.spotify.com/search/Tamally%20Maak%20Amr%20Diab', accent, 0),
          _trackTile('El Bahr Beydehak Leh', 'Hamza Namira', 'https://open.spotify.com/search/El%20Bahr%20Beydehak%20Leh%20Hamza%20Namira', accent, 1),
          _trackTile('Ya Rayah', 'Rachid Taha', 'https://open.spotify.com/search/Ya%20Rayah%20Rachid%20Taha', accent, 2),
          _trackTile('Ahu Da Elli Sar', 'Hamza Namira', 'https://open.spotify.com/search/Ahu%20Da%20Elli%20Sar%20Hamza%20Namira', accent, 3),
          _sectionHeader(context, 'Uplifting Classics', accent),
          _trackTile('Imagine', 'John Lennon', 'https://open.spotify.com/search/Imagine%20John%20Lennon', accent, 4),
          _trackTile('What a Wonderful World', 'Louis Armstrong', 'https://open.spotify.com/search/What%20a%20Wonderful%20World%20Louis%20Armstrong', accent, 5),
          _trackTile('Beautiful Day', 'U2', 'https://open.spotify.com/search/Beautiful%20Day%20U2', accent, 6),
        ];
      case 'fear':
      case 'surprise':
        return [
          _sectionHeader(context, 'Calm & Serenity', accent),
          _trackTile('Nesam Alayna El Hawa', 'Fairuz', 'https://open.spotify.com/search/Nesam%20Alayna%20El%20Hawa', accent, 0),
          _trackTile('Ya Ghali', 'Abdel Halim Hafez', 'https://open.spotify.com/search/Ya%20Ghali%20Abdel%20Halim', accent, 1),
          _trackTile('Aatini Al Naya', 'Fairuz', 'https://open.spotify.com/search/Fairuz%20Aatini%20Al%20Naya', accent, 2),
          _sectionHeader(context, 'Deep Relaxation', accent),
          _trackTile('Weightless', 'Marconi Union', 'https://open.spotify.com/search/Weightless%20Marconi%20Union', accent, 3),
          _trackTile('River Flows in You', 'Yiruma', 'https://open.spotify.com/search/Yiruma%20River%20Flows', accent, 4),
          _trackTile('Claire de Lune', 'Debussy', 'https://open.spotify.com/search/Clair%20de%20lune%20Debussy', accent, 5),
        ];
      case 'neutral':
        return [
          _sectionHeader(context, 'Arabic Chill', accent),
          _trackTile('Fiha Haga Helwa', 'Reham Abdel Hakim', 'https://open.spotify.com/search/Fiha%20Haga%20Helwa', accent, 0),
          _trackTile('Sahar El Layali', 'Fairuz', 'https://open.spotify.com/search/Sahar%20El%20Layali%20Fairuz', accent, 1),
          _trackTile('El Bent El Awiya', 'Wael Kfoury', 'https://open.spotify.com/search/El%20Bent%20El%20Awiya', accent, 2),
          _sectionHeader(context, 'Lofi & Acoustic', accent),
          _trackTile('Dernière Danse', 'Indila', 'https://open.spotify.com/search/Indila%20Dernière%20danse', accent, 3),
          _trackTile('Perfect', 'Ed Sheeran', 'https://open.spotify.com/search/Ed%20Sheeran%20Perfect', accent, 4),
          _trackTile('Lofi Hip Hop', 'Chill beats', 'https://open.spotify.com/search/lofi%20hip%20hop', accent, 5),
        ];
      case 'happy':
      default:
        return [
          _sectionHeader(context, 'Arabic Party', accent),
          _trackTile('Nour El Ein', 'Amr Diab', 'https://open.spotify.com/search/Nour%20El%20Ein%20Amr%20Diab', accent, 0),
          _trackTile('Samurai', 'Cairokee', 'https://open.spotify.com/search/Cairokee%20Samurai', accent, 1),
          _trackTile('Mesaytra', 'Lamis Kan', 'https://open.spotify.com/search/Mesaytra%20Lamis%20Kan', accent, 2),
          _trackTile('Hetta Tanya', 'Ruby', 'https://open.spotify.com/search/Ruby%20Hetta%20Tanya', accent, 3),
          _sectionHeader(context, 'Global Hits', accent),
          _trackTile('Happy', 'Pharrell Williams', 'https://open.spotify.com/search/Pharrell%20Happy', accent, 4),
          _trackTile("Don't Stop Me Now", 'Queen', 'https://open.spotify.com/search/Queen%20Don%27t%20Stop%20Me%20Now', accent, 5),
          _trackTile('Uptown Funk', 'Bruno Mars', 'https://open.spotify.com/search/Uptown%20Funk', accent, 6),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _themeColor(emotion);
    final gradientColors = [
      accent.withValues(alpha: 0.95),
      accent.withValues(alpha: 0.65),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Playlists'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BackgroundWidget(
        emotion: emotion,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.library_music_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Music for your mood',
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
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tap on any track to search on Spotify',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.92),
                                height: 1.35,
                              ),
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 12),
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
                      ..._content(context, accent),
                    ],
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
