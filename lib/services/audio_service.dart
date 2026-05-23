import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/track_model.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isRepeat = false;
  AudioTrack? _currentTrack;

  AudioPlayer get player => _player;
  bool get isRepeat => _isRepeat;
  bool get isPlaying => _player.state == PlayerState.playing;
  AudioTrack? get currentTrack => _currentTrack;

  Future<void> playTrack(AudioTrack track) async {
    _currentTrack = track;
    await _player.play(UrlSource(track.audioUrl));
    await _recordListening();
  }

  Future<void> togglePlayPause() async {
    if (_player.state == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> toggleRepeat() async {
    _isRepeat = !_isRepeat;
    await _player.setReleaseMode(
      _isRepeat ? ReleaseMode.loop : ReleaseMode.stop,
    );
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() => _player.dispose();

  Future<void> _recordListening() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];
    final key = 'listen_$today';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);

    final trackKey = 'tracks_$today';
    final String? json = prefs.getString(trackKey);
    List<String> tracks = json != null ? List<String>.from(jsonDecode(json)) : [];
    if (!tracks.contains(_currentTrack!.id)) {
      tracks.add(_currentTrack!.id);
      await prefs.setString(trackKey, jsonEncode(tracks));
    }
  }

  Future<int> getTotalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    int total = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith('listen_')) total += prefs.getInt(key) ?? 0;
    }
    return total;
  }

  Future<Map<String, int>> getDailyMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> data = {};
    final now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final key = date.toString().split(' ')[0];
      data[key] = prefs.getInt('listen_$key') ?? 0;
    }
    return data;
  }

  Future<List<MapEntry<String, int>>> getTopTracks({int limit = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> counts = {};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('tracks_')) {
        final String? json = prefs.getString(key);
        if (json != null) {
          for (final id in List<String>.from(jsonDecode(json))) {
            counts[id] = (counts[id] ?? 0) + 1;
          }
        }
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  Future<int> getMonthlyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('goal_hours') ?? 20;
  }

  Future<void> setMonthlyGoal(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('goal_hours', hours);
  }
}
