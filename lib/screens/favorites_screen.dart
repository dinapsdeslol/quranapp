import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/favorites_service.dart';
import '../services/biometric_service.dart';
import '../services/audio_player_service.dart';
import '../models/audio_track.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final BiometricService _biometricService = BiometricService();
  final AudioPlayerService _audioService = AudioPlayerService();

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _removeFavorite(AudioTrack track) async {
    final authenticated = await _biometricService.authenticate(
      reason: 'Verify your identity to remove this favorite',
    );

    if (authenticated && mounted) {
      await _favoritesService.removeFromFavorites(track.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites')),
        );
      }
    }
  }

  Future<void> _playTrack(AudioTrack track) async {
    await _audioService.play(track);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AudioTrack>>(
      stream: _favoritesService.getFavoritesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error loading favorites'),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final favorites = snapshot.data ?? [];

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No favorites yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add tracks to your favorites from the Player tab',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: favorites.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final track = favorites[index];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Icon(
                  Icons.music_note,
                  color: Colors.teal.shade700,
                ),
              ),
              title: Text(
                track.surahEnglishName.isNotEmpty
                    ? '${track.surahEnglishName} - Ayah ${track.ayahNumber}'
                    : 'Ayah ${track.ayahNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(track.surahName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _playTrack(track),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeFavorite(track),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
