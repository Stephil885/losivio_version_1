// losivio/lib/widgets/media_preview.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaPreview extends StatefulWidget {
  final String filePath;
  final VoidCallback onDelete; // Pour la suppression

  const MediaPreview({
    super.key,
    required this.filePath,
    required this.onDelete,
  });

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  void _initializeMedia() {
    final file = File(widget.filePath);
    final extension = file.path.split('.').last.toLowerCase();

    // Détermine si c'est une vidéo (simplifié aux extensions courantes)
    if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      _isVideo = true;
      _videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isControllerInitialized = true;
              _videoController!.setLooping(true);
              _videoController!.play(); // Lecture automatique
            });
          }
        }).catchError((e) {
          debugPrint("Erreur lecture vidéo: $e");
        });
    } else {
      _isVideo = false;
      _isControllerInitialized = true; // Image toujours prête
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isControllerInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Stack(
      children: [
        // 1. Affichage du Média
        Positioned.fill(
          child: _isVideo && _videoController!.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                )
              : Image.file(
                  File(widget.filePath),
                  fit: BoxFit.contain, // Utiliser contain pour ne pas déborder
                ),
        ),

        // 2. Contrôle de lecture vidéo
        if (_isVideo)
          Center(
            child: FloatingActionButton(
              heroTag: widget.filePath, // Évite les erreurs de tag dupliqué
              backgroundColor: Colors.white30,
              onPressed: () {
                setState(() {
                  _videoController!.value.isPlaying 
                      ? _videoController!.pause()
                      : _videoController!.play();
                });
              },
              child: Icon(
                _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        
        // 3. Bouton Supprimer
        Positioned(
          top: 50,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 30),
            onPressed: widget.onDelete,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}