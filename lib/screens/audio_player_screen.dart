import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/quran_api_service.dart';
import '../services/audio_player_service.dart';
import '../services/favorites_service.dart';
import '../services/biometric_service.dart';
import '../models/audio_track.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final QuranApiService _apiService = QuranApiService();
  final AudioPlayerService _audioService = AudioPlayerService();
  final FavoritesService _favoritesService = FavoritesService();
  final BiometricService _biometricService = BiometricService();

  List<Map<String, dynamic>> _categories = [];
  AudioTrack? _currentTrack;
  bool _isLoading = true;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isRepeat = false;
  Map<String, bool> _favoritesMap = {};
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _audioService.player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _saveListeningMinutes();
      }
    });

    _audioService.player.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioService.player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  Future<void> _saveListeningMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final String today = DateTime.now().toString().split(' ')[0];
    final String key = 'listening_time_$today';
    int minutes = prefs.getInt(key) ?? 0;

    if (_currentPosition.inSeconds % 60 == 0 && _currentPosition.inSeconds > 0) {
      await prefs.setInt(key, minutes + 1);
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _apiService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    }
  }

  Future<void> _playTrack(AudioTrack track) async {
    await _audioService.play(track);
    if (mounted) {
      setState(() {
        _currentTrack = track;
      });
    }
  }

  Future<void> _toggleFavorite(AudioTrack track) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isFav = _favoritesMap[track.id] ?? false;

    if (isFav) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Verify your identity to remove favorite',
      );

      if (authenticated) {
        await _favoritesService.removeFromFavorites(track.id);
        if (mounted) {
          setState(() {
            _favoritesMap[track.id] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        }
      }
    } else {
      await _favoritesService.addToFavorites(track);
      if (mounted) {
        setState(() {
          _favoritesMap[track.id] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites')),
        );
      }
    }
  }

  Future<void> _loadFavorites() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    final favorites = await _favoritesService.getFavorites();
    if (mounted) {
      setState(() {
        _favoritesMap = {for (var f in favorites) f.id: true};
      });
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_currentTrack != null) _buildPlayer(),
        Expanded(
          child: _buildCategoryList(),
        ),
      ],
    );
  }

  Widget _buildPlayer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade900],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTrack!.surahEnglishName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Ayah ${_currentTrack!.ayahNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _favoritesMap[_currentTrack!.id] ?? false
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: _favoritesMap[_currentTrack!.id] ?? false
                      ? Colors.red
                      : Colors.white,
                ),
                onPressed: () => _toggleFavorite(_currentTrack!),
              ),
            ],
          ),
          Slider(
            value: _currentPosition.inSeconds.toDouble(),
            max: _totalDuration.inSeconds.toDouble().clamp(1, double.infinity),
            onChanged: (value) {
              _audioService.seek(Duration(seconds: value.toInt()));
            },
            activeColor: Colors.white,
            inactiveColor: Colors.white.withOpacity(0.3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _isRepeat ? Icons.repeat_one : Icons.repeat,
                  color: _isRepeat ? Colors.yellow : Colors.white,
                ),
                onPressed: () {
                  _audioService.toggleRepeat();
                  setState(() {
                    _isRepeat = !_isRepeat;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 40,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (_isPlaying) {
                    _audioService.pause();
                  } else {
                    _audioService.resume();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.white),
                onPressed: () {
                  _audioService.stop();
                  setState(() {
                    _currentPosition = Duration.zero;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final tracks = category['tracks'] as List<AudioTrack>;

        return ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Colors.teal.shade100,
            child: Text(
              '${index + 1}',
              style: TextStyle(color: Colors.teal.shade700),
            ),
          ),
          title: Text(
            category['englishName'] ?? category['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${tracks.length} ayahs'),
          children: tracks.map((track) => _buildTrackTile(track)).toList(),
        );
      },
    );
  }

  Widget _buildTrackTile(AudioTrack track) {
    final isCurrentTrack = _currentTrack?.id == track.id;

    return ListTile(
      leading: Icon(
        isCurrentTrack && _isPlaying ? Icons.play_arrow : Icons.audiotrack,
        color: isCurrentTrack ? Colors.teal : Colors.grey,
      ),
      title: Text(
        'Ayah ${track.ayahNumber}',
        style: TextStyle(
          color: isCurrentTrack ? Colors.teal : null,
          fontWeight: isCurrentTrack ? FontWeight.bold : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.play_arrow,
              color: isCurrentTrack ? Colors.teal : null,
            ),
            onPressed: () => _playTrack(track),
          ),
        ],
      ),
      onTap: () => _playTrack(track),
    );
  }
}
