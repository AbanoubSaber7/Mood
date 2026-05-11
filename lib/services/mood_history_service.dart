import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mood_app/models/mood_history_entry.dart';

class MoodHistoryService {
  static const String _key = 'mood_history_entries_v1';

  Future<String> _keyForUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('user_id');
      if (stored != null && stored.isNotEmpty) return _key + '_' + stored;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      return _key + '_' + (uid ?? 'anon');
    } catch (_) {
      return _key + '_anon';
    }
  }

  Future<List<MoodHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _keyForUser();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => MoodHistoryEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<MoodHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _keyForUser();
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  Future<void> addEntry(MoodHistoryEntry entry, {int maxEntries = 20}) async {
    final entries = await load();
    final updated = [entry, ...entries];
    final capped = updated.take(maxEntries).toList();
    await save(capped);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _keyForUser();
    await prefs.remove(key);
  }

  /// If there are entries stored under the anonymous key, move them to the
  /// current user's key (if signed in) and remove the anonymous key.
  Future<void> transferAnonToCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final anonKey = _key + '_anon';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userKey = _key + '_' + uid;

    final anonRaw = prefs.getString(anonKey);
    if (anonRaw == null || anonRaw.trim().isEmpty) return;

    try {
      final decodedAnon = jsonDecode(anonRaw);
      if (decodedAnon is! List) return;
      final anonEntries = decodedAnon
          .whereType<Map>()
          .map((m) => MoodHistoryEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList();

      // load existing for user
      final userRaw = prefs.getString(userKey);
      List<MoodHistoryEntry> userEntries = [];
      if (userRaw != null && userRaw.trim().isNotEmpty) {
        final decodedUser = jsonDecode(userRaw);
        if (decodedUser is List) {
          userEntries = decodedUser
              .whereType<Map>()
              .map(
                (m) => MoodHistoryEntry.fromJson(Map<String, dynamic>.from(m)),
              )
              .toList();
        }
      }

      // merge: keep anon entries first (most-recent), then existing user entries
      final merged = [...anonEntries, ...userEntries];
      final encoded = jsonEncode(merged.map((e) => e.toJson()).toList());
      await prefs.setString(userKey, encoded);
      await prefs.remove(anonKey);
    } catch (_) {
      // ignore parsing errors
      return;
    }
  }
}
