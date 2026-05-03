class Surah {
  final String id;
  final String name;
  final String englishName;
  final int numberOfAyahs;

  Surah({
    required this.id,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      numberOfAyahs: json['numberOfAyahs'] ?? 0,
    );
  }
}
