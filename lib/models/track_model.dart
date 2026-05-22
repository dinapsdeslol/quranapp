class AudioTrack {
  final String id;
  final String surahName;
  final String surahEnglishName;
  final int ayahNumber;
  final String audioUrl;

  AudioTrack({
    required this.id,
    required this.surahName,
    required this.surahEnglishName,
    required this.ayahNumber,
    required this.audioUrl,
  });

  String get title => '$surahEnglishName - Ayah $ayahNumber';
}

class SurahCategory {
  final String id;
  final String name;
  final String englishName;
  final List<AudioTrack> tracks;

  SurahCategory({
    required this.id,
    required this.name,
    required this.englishName,
    required this.tracks,
  });
}
