class AudioTrack {
  final String id;
  final String surahId;
  final String surahName;
  final String surahEnglishName;
  final int ayahNumber;
  final String audioUrl;

  AudioTrack({
    required this.id,
    required this.surahId,
    required this.surahName,
    required this.surahEnglishName,
    required this.ayahNumber,
    required this.audioUrl,
  });

  String get displayName => '${surahEnglishName.isNotEmpty ? "$surahEnglishName - " : ""}Ayah $ayahNumber';
}
