// widget/post_card.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostCard extends StatefulWidget {
  final String videoUrl;
  final String username;
  final String caption;
  final String music;

  const PostCard({
    super.key,
    required this.videoUrl,
    required this.username,
    required this.caption,
    required this.music,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Vidéo plein écran
        SizedBox.expand(
          child: _controller.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),

        // Overlay d’infos
        Positioned(
          bottom: 60,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.username,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.caption,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(widget.music,
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),

        // Boutons à droite
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: const [
              Icon(Icons.favorite, color: Colors.white, size: 32),
              SizedBox(height: 24),
              Icon(Icons.comment, color: Colors.white, size: 32),
              SizedBox(height: 24),
              Icon(Icons.share, color: Colors.white, size: 32),
              SizedBox(height: 24),
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                    'https://avatars.githubusercontent.com/u/9919?s=200&v=4'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
