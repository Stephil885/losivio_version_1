// lib/models/media_model.dart

class MediaModel {
  final int id;
  final String url; 
  final String mediaType;
  final String? title;
  final String? bunnyVideoId; 
  final String? filter;
  final String? thumbnailUrl;
  // --- Nouveaux champs pour la traduction ---
  final bool allowTranslation; 
  final String? translatedAudioUrl;
  final String? translatedText;
  final String? videoUrlTranslate;

  MediaModel({
    required this.id,
    required this.url,
    required this.mediaType,
    this.title,
    this.bunnyVideoId,
    this.filter,
    this.thumbnailUrl,
    this.allowTranslation = false,
    this.translatedAudioUrl,
    this.translatedText,
    this.videoUrlTranslate,
  });

  bool get isVideo => mediaType == 'video';
  // Vérifie si une traduction est réellement disponible pour ce média
  bool get hasTranslation => translatedAudioUrl != null && translatedAudioUrl!.isNotEmpty;

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      url: json['url'] ?? '',
      mediaType: json['mediaType'] ?? 'image',
      title: json['title'],
      bunnyVideoId: json['bunnyVideoId'],
      filter: json['filter'],
      thumbnailUrl: json['thumbnailUrl'] ?? json['url'],
      // Mappage des nouveaux champs (assure-toi que ton SQL backend les renvoie)
      allowTranslation: json['translation'] == 1 || json['translation'] == true,
      translatedAudioUrl: json['translatedAudioUrl'],
      translatedText: json['translatedText'],
      videoUrlTranslate: json['videoUrlTranslate'],
    );
  }
}