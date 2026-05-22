import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/favorite_service.dart';
import '../services/audio_service.dart';
import '../services/bio_service.dart';
import '../models/track_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService? _fav = kIsWeb ? null : FavoriteService();
  final AudioService _audio = AudioService();
  final BioService? _bio = kIsWeb ? null : BioService();

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Favorites available on mobile', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Requires Firebase', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return StreamBuilder(
      stream: _fav!.stream(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

        final favs = snap.data ?? [];
        if (favs.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.favorite_border, size: 80, color: Colors.grey), SizedBox(height: 16), Text('No favorites yet', style: TextStyle(fontSize: 18, color: Colors.grey))]));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8), itemCount: favs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final t = favs[i];
            return ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: Icon(Icons.music_note, color: Colors.blue.shade700)),
              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(t.surahName),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.play_arrow), onPressed: () => _audio.playTrack(t)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(t)),
              ]),
            );
          },
        );
      },
    );
  }

  Future<void> _delete(AudioTrack t) async {
    if (_bio == null) return;
    final ok = await _bio!.requireAuthForDelete();
    if (ok && mounted) {
      await _fav!.remove(t.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    }
  }
}
