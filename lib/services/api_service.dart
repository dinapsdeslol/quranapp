import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';

class QuranApiService {
  static const String baseUrl = 'https://quran.yousefheiba.com/en';

  Future<List<SurahCategory>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/surahs'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          return SurahCategory(
            id: json['id'].toString(),
            name: json['name'] ?? '',
            englishName: json['englishName'] ?? '',
            tracks: [],
          );
        }).toList();
      }
    } catch (e) {}
    return _getFallbackCategories();
  }

  Future<List<AudioTrack>> getTracks(String surahId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/surahs/$surahId/tracks'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          return AudioTrack(
            id: json['id'].toString(),
            surahName: json['surahName'] ?? '',
            surahEnglishName: json['surahEnglishName'] ?? '',
            ayahNumber: json['ayahNumber'] ?? 0,
            audioUrl: json['audioUrl'] ?? '',
          );
        }).toList();
      }
    } catch (e) {}
    return [];
  }

  List<SurahCategory> _getFallbackCategories() {
    return [
      SurahCategory(id: '1', name: 'الفاتحة', englishName: 'Al-Fatiha', tracks: []),
      SurahCategory(id: '2', name: 'البقرة', englishName: 'Al-Baqarah', tracks: []),
      SurahCategory(id: '36', name: 'يس', englishName: 'Ya-Sin', tracks: []),
      SurahCategory(id: '55', name: 'الرحمن', englishName: 'Ar-Rahman', tracks: []),
      SurahCategory(id: '67', name: 'الملك', englishName: 'Al-Mulk', tracks: []),
      SurahCategory(id: '112', name: 'الإخلاص', englishName: 'Al-Ikhlas', tracks: []),
      SurahCategory(id: '113', name: 'الفلق', englishName: 'Al-Falaq', tracks: []),
      SurahCategory(id: '114', name: 'الناس', englishName: 'An-Nas', tracks: []),
    ];
  }
}
