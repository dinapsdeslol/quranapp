import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/track_model.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> add(AudioTrack track) async {
    if (_uid == null) return;
    await _firestore.collection('users').doc(_uid).collection('favorites').doc(track.id).set({
      'id': track.id,
      'surahName': track.surahName,
      'surahEnglishName': track.surahEnglishName,
      'ayahNumber': track.ayahNumber,
      'audioUrl': track.audioUrl,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String trackId) async {
    if (_uid == null) return;
    await _firestore.collection('users').doc(_uid).collection('favorites').doc(trackId).delete();
  }

  Stream<List<AudioTrack>> stream() {
    if (_uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return AudioTrack(
                id: d['id'] ?? '',
                surahName: d['surahName'] ?? '',
                surahEnglishName: d['surahEnglishName'] ?? '',
                ayahNumber: d['ayahNumber'] ?? 0,
                audioUrl: d['audioUrl'] ?? '',
              );
            }).toList());
  }
}
