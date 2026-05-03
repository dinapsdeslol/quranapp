import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/audio_track.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  bool _isRepeat = false;

  AudioPlayer get player => _player;
  bool get isRepeat => _isRepeat;

  AudioPlayerService() {
    _player.onPlayerComplete.listen((_) {
      if (_isRepeat) {
        _player.resume();
      }
    });
  }

  Future<void> play(AudioTrack track) async {
    await _player.stop();
    await _player.setSource(UrlSource(track.audioUrl));
    await _player.resume();
    await _saveListeningTime(track);
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> toggleRepeat() async {
    _isRepeat = !_isRepeat;
    if (!_isRepeat) {
      _player.setReleaseMode(ReleaseMode.stop);
    } else {
      _player.setReleaseMode(ReleaseMode.loop);
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
  }

  Future<void> _saveListeningTime(AudioTrack track) async {
    final prefs = await SharedPreferences.getInstance();
    final String today = DateTime.now().toString().split(' ')[0];
    final String key = 'listening_time_$today';
    final String keyTracks = 'listened_tracks_$today';

    int currentMinutes = prefs.getInt(key) ?? 0;
    List<String> listenedTracks = [];
    final String? tracksJson = prefs.getString(keyTracks);
    if (tracksJson != null) {
      listenedTracks = List<String>.from(jsonDecode(tracksJson));
    }

    if (!listenedTracks.contains(track.id)) {
      listenedTracks.add(track.id);
      await prefs.setString(keyTracks, jsonEncode(listenedTracks));
    }
  }

  Future<Map<String, int>> getDailyListeningMinutes({int days = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> dailyMinutes = {};

    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = date.toString().split(' ')[0];
      final key = 'listening_time_$dateKey';
      dailyMinutes[dateKey] = prefs.getInt(key) ?? 0;
    }

    return dailyMinutes;
  }

  Future<int> getTotalListeningMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    int total = 0;

    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('listening_time_')) {
        total += prefs.getInt(key) ?? 0;
      }
    }

    return total;
  }

  Future<List<MapEntry<String, int>>> getTopTracks({int limit = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> trackCounts = {};

    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('listened_tracks_')) {
        final String? tracksJson = prefs.getString(key);
        if (tracksJson != null) {
          final List<dynamic> tracks = jsonDecode(tracksJson);
          for (final trackId in tracks) {
            trackCounts[trackId] = (trackCounts[trackId] ?? 0) + 1;
          }
        }
      }
    }

    final sorted = trackCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).toList();
  }
}
