import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/audio_track.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  Future<void> addToFavorites(AudioTrack track) async {
    if (userId == null) return;

    final trackData = {
      'id': track.id,
      'surahId': track.surahId,
      'surahName': track.surahName,
      'surahEnglishName': track.surahEnglishName,
      'ayahNumber': track.ayahNumber,
      'audioUrl': track.audioUrl,
      'addedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(track.id)
        .set(trackData);
  }

  Future<void> removeFromFavorites(String trackId) async {
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(trackId)
        .delete();
  }

  Future<bool> isFavorite(String trackId) async {
    if (userId == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(trackId)
        .get();

    return doc.exists;
  }

  Stream<List<AudioTrack>> getFavoritesStream() {
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AudioTrack(
          id: data['id'] ?? '',
          surahId: data['surahId'] ?? '',
          surahName: data['surahName'] ?? '',
          surahEnglishName: data['surahEnglishName'] ?? '',
          ayahNumber: data['ayahNumber'] ?? 0,
          audioUrl: data['audioUrl'] ?? '',
        );
      }).toList();
    });
  }

  Future<List<AudioTrack>> getFavorites() async {
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AudioTrack(
        id: data['id'] ?? '',
        surahId: data['surahId'] ?? '',
        surahName: data['surahName'] ?? '',
        surahEnglishName: data['surahEnglishName'] ?? '',
        ayahNumber: data['ayahNumber'] ?? 0,
        audioUrl: data['audioUrl'] ?? '',
      );
    }).toList();
  }
}
