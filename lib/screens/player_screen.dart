import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/favorite_service.dart';
import '../services/bio_service.dart';
import '../models/track_model.dart';

class PlayerScreen extends StatefulWidget {
  final AudioService audio;
  const PlayerScreen({super.key, required this.audio});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final QuranApiService _api = QuranApiService();
  late final AudioService _audio = widget.audio;
  final FavoriteService? _fav = kIsWeb ? null : FavoriteService();
  final BioService? _bio = kIsWeb ? null : BioService();

  List<SurahCategory> _categories = [];
  bool _loading = true;
  double _posSec = 0;
  double _durSec = 0;
  bool _playing = false;
  bool _repeat = false;
  Set<String> _favIds = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFavIds();
    _audio.player.onPositionChanged.listen((p) {
      if (!mounted) return;
      final s = p.inMilliseconds / 1000.0;
      if (s <= _durSec || _durSec == 0) setState(() => _posSec = s);
    });
    _audio.player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _durSec = d.inMilliseconds / 1000.0);
    });
    _audio.player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
    _audio.player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      if (s == PlayerState.stopped) setState(() { _playing = false; _posSec = 0; });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFavIds() async {
    if (kIsWeb) return;
    try {
      final favs = await _fav!.stream().first;
      if (mounted) setState(() => _favIds = favs.map((t) => t.id).toSet());
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    final cats = await _api.getCategories();
    if (mounted) setState(() { _categories = cats; _loading = false; });
  }

  Future<void> _playSurah(SurahCategory cat) async {
    final url = cat.audioUrl;
    if (url == null || url.isEmpty) return;
    final track = AudioTrack(
      id: cat.id,
      surahName: cat.name,
      surahEnglishName: cat.englishName,
      ayahNumber: 0,
      audioUrl: url,
    );
    setState(() { _posSec = 0; _durSec = 0; _playing = true; });
    try {
      await _audio.playTrack(track);
    } catch (_) {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _togglePlay() async {
    await _audio.togglePlayPause();
    if (mounted) setState(() => _playing = _audio.isPlaying);
  }

  Future<void> _toggleFav(AudioTrack t) async {
    if (kIsWeb) return;
    final isFav = _favIds.contains(t.id);
    if (isFav) {
      final ok = await _bio!.requireAuthForDelete();
      if (ok && mounted) {
        await _fav!.remove(t.id);
        setState(() => _favIds.remove(t.id));
      }
    } else {
      await _fav!.add(t);
      if (mounted) setState(() => _favIds.add(t.id));
    }
  }

  String _fmt(double sec) {
    final d = Duration(milliseconds: (sec * 1000).round());
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        if (_audio.currentTrack != null) _buildPlayer(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildPlayer() {
    final t = _audio.currentTrack!;
    final maxVal = _durSec > 0 ? _durSec : 1.0;
    final sliderVal = _posSec.clamp(0.0, maxVal);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)]),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.surahEnglishName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Text('Full Surah', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              if (!kIsWeb) IconButton(
                icon: Icon(_favIds.contains(t.id) ? Icons.favorite : Icons.favorite_border, color: _favIds.contains(t.id) ? Colors.red : Colors.white),
                onPressed: () => _toggleFav(t),
              ),
            ],
          ),
          Slider(value: sliderVal, max: maxVal, onChanged: (v) => _audio.seek(Duration(milliseconds: (v * 1000).round())), activeColor: Colors.white, inactiveColor: Colors.white30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_fmt(_posSec), style: const TextStyle(color: Colors.white70, fontSize: 12)), Text(_fmt(_durSec), style: const TextStyle(color: Colors.white70, fontSize: 12))]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: Icon(_repeat ? Icons.repeat_one : Icons.repeat, color: _repeat ? Colors.yellow : Colors.white), onPressed: () async { await _audio.toggleRepeat(); if (mounted) setState(() => _repeat = _audio.isRepeat); }),
              IconButton(icon: Icon(_playing ? Icons.pause : Icons.play_arrow, size: 40, color: Colors.white), onPressed: _togglePlay),
              IconButton(icon: const Icon(Icons.stop, color: Colors.white), onPressed: () async { await _audio.stop(); if (mounted) setState(() { _playing = false; _posSec = 0; }); }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (_, i) {
        final cat = _categories[i];
        final isCurrent = _audio.currentTrack?.id == cat.id;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isCurrent ? Colors.blue : Colors.blue.shade100,
            child: Text('${i + 1}', style: TextStyle(color: isCurrent ? Colors.white : Colors.blue.shade700)),
          ),
          title: Text(cat.englishName, style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? Colors.blue : null)),
          subtitle: Text(cat.name, style: TextStyle(color: isCurrent ? Colors.blue.shade300 : Colors.grey)),
          trailing: Icon(isCurrent ? Icons.play_arrow : Icons.play_circle_outline, color: isCurrent ? Colors.blue : null),
          onTap: () => _playSurah(cat),
        );
      },
    );
  }
}
