import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';

class QuranApiService {
  static const String baseUrl = 'https://staticquran.vercel.app/api/v1';

  String _audioUrl(String id) {
    final padded = id.padLeft(3, '0');
    return 'https://download.quranicaudio.com/quran/yasser_ad-dussary/$padded.mp3';
  }

  Future<List<SurahCategory>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/surah'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) {
          final id = json['sequence'].toString();
          return SurahCategory(
            id: id,
            name: json['name']['arabic']['short'] ?? '',
            englishName: json['name']['latin']['short'] ?? json['translation'] ?? '',
            audioUrl: _audioUrl(id),
            tracks: [],
          );
        }).toList();
      }
    } catch (e) {}
    return _getFallbackCategories();
  }

  List<SurahCategory> _getFallbackCategories() {
    return [
      SurahCategory(id: '1', name: 'الفاتحة', englishName: 'Al-Fatiha', audioUrl: _audioUrl('1')),
      SurahCategory(id: '2', name: 'البقرة', englishName: 'Al-Baqarah', audioUrl: _audioUrl('2')),
      SurahCategory(id: '36', name: 'يس', englishName: 'Ya-Sin', audioUrl: _audioUrl('36')),
      SurahCategory(id: '55', name: 'الرحمن', englishName: 'Ar-Rahman', audioUrl: _audioUrl('55')),
      SurahCategory(id: '67', name: 'الملك', englishName: 'Al-Mulk', audioUrl: _audioUrl('67')),
      SurahCategory(id: '112', name: 'الإخلاص', englishName: 'Al-Ikhlas', audioUrl: _audioUrl('112')),
      SurahCategory(id: '113', name: 'الفلق', englishName: 'Al-Falaq', audioUrl: _audioUrl('113')),
      SurahCategory(id: '114', name: 'الناس', englishName: 'An-Nas', audioUrl: _audioUrl('114')),
    ];
  }
}
