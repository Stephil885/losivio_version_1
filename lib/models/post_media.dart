// lib/models/post_media.dart
import 'package:flutter/material.dart';
import '../forms/components/filters.dart'; // Import crucial ici

class PostMedia {
  final String path;
  final String type; 
  final CameraFilter filter; // <--- On ajoute la mémoire du filtre
  final int duration;
  String caption; 
  bool allowTranslation;
  bool allowSousTitre;
  final TextEditingController captionController;

  PostMedia({
    required this.path,
    required this.type,
    this.filter = CameraFilter.none, // Par défaut, pas de filtre
    this.duration = 0,
    this.caption = "",
    this.allowTranslation = false, // Valeur par défaut
    this.allowSousTitre = false,   // Valeur par défaut
  }) : captionController = TextEditingController(text: caption);

  void updateCaption() {
    caption = captionController.text;
  }

  @override
  String toString() => 'PostMedia(path: $path, type: $type, filter: ${filter.label}, caption: $caption)';
}