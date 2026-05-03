import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/audio_track.dart';
import '../models/surah.dart';

class QuranApiService {
  static const String baseUrl = 'https://quran.yousefheiba.com/en';

  Future<List<Surah>> getSurahs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/surahs'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Surah.fromJson(json)).toList();
      } else {
        return _getMockSurahs();
      }
    } catch (e) {
      return _getMockSurahs();
    }
  }

  Future<List<AudioTrack>> getTracksForSurah(String surahId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/surahs/$surahId/tracks'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AudioTrack(
          id: json['id'].toString(),
          surahId: json['surahId'].toString(),
          surahName: json['surahName'] ?? '',
          surahEnglishName: json['surahEnglishName'] ?? '',
          ayahNumber: json['ayahNumber'] ?? 0,
          audioUrl: json['audioUrl'] ?? '',
        )).toList();
      } else {
        return _getMockTracks(surahId);
      }
    } catch (e) {
      return _getMockTracks(surahId);
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final surahs = await getSurahs();
    final categories = <Map<String, dynamic>>[];

    for (final surah in surahs) {
      final tracks = await getTracksForSurah(surah.id);
      categories.add({
        'id': surah.id,
        'name': surah.name,
        'englishName': surah.englishName,
        'tracks': tracks,
      });
    }

    return categories;
  }

  List<Surah> _getMockSurahs() {
    return [
      Surah(id: '1', name: 'الفاتحة', englishName: 'Al-Fatiha', numberOfAyahs: 7),
      Surah(id: '2', name: 'البقرة', englishName: 'Al-Baqarah', numberOfAyahs: 286),
      Surah(id: '3', name: 'آل عمران', englishName: 'Ali \'Imran', numberOfAyahs: 200),
      Surah(id: '36', name: 'يس', englishName: 'Ya-Sin', numberOfAyahs: 83),
      Surah(id: '55', name: 'الرحمن', englishName: 'Ar-Rahman', numberOfAyahs: 78),
      Surah(id: '67', name: 'الملك', englishName: 'Al-Mulk', numberOfAyahs: 30),
      Surah(id: '112', name: 'الإخلاص', englishName: 'Al-Ikhlas', numberOfAyahs: 4),
      Surah(id: '113', name: 'الفلق', englishName: 'Al-Falaq', numberOfAyahs: 5),
      Surah(id: '114', name: 'الناس', englishName: 'An-Nas', numberOfAyahs: 6),
    ];
  }

  List<AudioTrack> _getMockTracks(String surahId) {
    final surahNames = {
      '1': 'Al-Fatiha',
      '2': 'Al-Baqarah',
      '3': 'Ali \'Imran',
      '36': 'Ya-Sin',
      '55': 'Ar-Rahman',
      '67': 'Al-Mulk',
      '112': 'Al-Ikhlas',
      '113': 'Al-Falaq',
      '114': 'An-Nas',
    };

    final ayahCounts = {
      '1': 7,
      '2': 10,
      '3': 10,
      '36': 10,
      '55': 10,
      '67': 10,
      '112': 4,
      '113': 5,
      '114': 6,
    };

    final tracks = <AudioTrack>[];
    final count = ayahCounts[surahId] ?? 7;
    final surahName = surahNames[surahId] ?? 'Unknown';

    for (int i = 1; i <= count; i++) {
      tracks.add(AudioTrack(
        id: '${surahId}_$i',
        surahId: surahId,
        surahName: surahName,
        surahEnglishName: surahName,
        ayahNumber: i,
        audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${_getAyahNumberGlobal(int.parse(surahId), i)}.mp3',
      ));
    }

    return tracks;
  }

  int _getAyahNumberGlobal(int surah, int ayah) {
    final Map<int, int> ayahStart = {
      1: 0,
      2: 7,
      3: 293,
      4: 493,
      5: 775,
      6: 875,
      7: 1025,
      36: 3809,
      55: 4839,
      67: 5298,
      112: 6156,
      113: 6160,
      114: 6165,
    };

    int base = 0;
    for (final entry in ayahStart.entries) {
      if (entry.key == surah) {
        base = entry.value;
        break;
      }
      if (entry.key > surah) {
        base = entry.value;
        break;
      }
    }

    return base + ayah;
  }
}
