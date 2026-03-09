import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'; 
import 'package:dio/dio.dart';
import '../config/api_config.dart';

// Palette cohérente avec ChatScreen
const Color kSurfaceColor = Color(0xFF1E293B);
const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

class ChatBubble extends StatefulWidget {
  final int? id;
  final String message;
  final bool isMe;
  final String time;
  final bool isAudio;
  final String? audioPath;
  final String? duration;
  final bool isImage;
  final String? imagePath;
  final bool isVideo;
  final String? videoPath;
  final bool isSticker;
  final String? stickerPath;
  final Map<String, dynamic>? replyTo;
  final VoidCallback onReply;

  const ChatBubble({
    super.key,
    this.id,
    required this.message,
    required this.isMe,
    required this.time,
    this.isAudio = false,
    this.audioPath,
    this.duration,
    this.isImage = false,
    this.imagePath,
    this.isVideo = false,
    this.videoPath,
    this.isSticker = false,
    this.stickerPath,
    this.replyTo,
    required this.onReply,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with AutomaticKeepAliveClientMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isPlayerReady = false;
  bool _showVideoPlayer = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  String _formatUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return "${ApiConfig.avatarUrl}/$cleanPath";
  }

  // --- LOGIQUE PREMIUM UI ---

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Dismissible(
      key: ValueKey(widget.id ?? widget.time + widget.message),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        widget.onReply();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(left: 24),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.reply_rounded, color: Color(0xFFEC4899), size: 28),
      ),
      child: widget.isSticker && widget.stickerPath != null
          ? _buildStickerLayout()
          : _buildStandardBubble(context),
    );
  }

  Widget _buildStandardBubble(BuildContext context) {
    bool isMedia = widget.isImage || widget.isVideo;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          // Gradient pour MOI, Couleur sombre premium pour l'AUTRE
          gradient: widget.isMe ? kAccentGradient : null,
          color: widget.isMe ? null : kSurfaceColor,
          borderRadius: _getBorderRadius(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyTo != null) _buildReplyMetadata(),
            _buildContent(),
            if (!isMedia) _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isImage && widget.imagePath != null) {
      final imageUrl = _formatUrl(widget.imagePath);
      return _buildMediaWrapper(
        GestureDetector(
          onTap: () => _openFullScreenImage(context, imageUrl),
          child: ClipRRect(
            borderRadius: _getBorderRadius(inner: true),
            child: Hero(
              tag: imageUrl,
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
        ),
      );
    }

    if (widget.isVideo && widget.videoPath != null) {
      return _buildMediaWrapper(
        GestureDetector(
          onTap: _startVideo,
          child: ClipRRect(
            borderRadius: _getBorderRadius(inner: true),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  color: Colors.black45,
                  child: _showVideoPlayer && _isPlayerReady
                      ? Chewie(controller: _chewieController!)
                      : const Icon(Icons.play_circle_outline, color: Colors.white60, size: 64),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.isAudio || (widget.audioPath != null)) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: _buildAudioPlayer(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        widget.message,
        style: TextStyle(
          color: widget.isMe ? Colors.white : Colors.white.withOpacity(0.9),
          fontSize: 15,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _toggleAudio,
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              color: widget.isMe ? Colors.white : const Color(0xFF22D3EE),
              size: 38,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.duration ?? "Message vocal",
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyMetadata() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: widget.isMe ? Colors.white : const Color(0xFFEC4899), width: 3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.reply, size: 14, color: Colors.white60),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.replyTo!['text'] ?? "Média",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter({bool isOverMedia = false}) {
    return Padding(
      padding: isOverMedia 
          ? const EdgeInsets.all(8) 
          : const EdgeInsets.only(left: 16, right: 12, bottom: 8, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            widget.time,
            style: TextStyle(
              color: isOverMedia ? Colors.white : Colors.white38,
              fontSize: 10,
              fontWeight: isOverMedia ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (widget.isMe) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.done_all_rounded, 
              size: 14, 
              color: isOverMedia ? Colors.white : const Color(0xFF22D3EE)
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMediaWrapper(Widget child) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        child,
        _buildFooter(isOverMedia: true),
      ],
    );
  }

  Widget _buildStickerLayout() {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Image.asset(widget.stickerPath!, width: 140, height: 140),
      ),
    );
  }

  BorderRadius _getBorderRadius({bool inner = false}) {
    double r = inner ? 18 : 22;
    return BorderRadius.only(
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
      bottomLeft: widget.isMe ? Radius.circular(r) : const Radius.circular(4),
      bottomRight: widget.isMe ? const Radius.circular(4) : Radius.circular(r),
    );
  }

  // --- LOGIQUE MEDIA (Vidéos/Images) identique à votre précédente version mais adaptée ---
  Future<void> _startVideo() async {
    setState(() => _showVideoPlayer = true);
    if (_videoPlayerController != null) return;
    final url = _formatUrl(widget.videoPath);
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        autoPlay: true,
      );
      if (mounted) setState(() => _isPlayerReady = true);
    } catch (e) { debugPrint("Erreur Vidéo: $e"); }
  }

  Future<void> _toggleAudio() async {
    if (widget.audioPath == null) return;
    final url = _formatUrl(widget.audioPath);
    if (_isPlaying) { await _audioPlayer.pause(); } 
    else { await _audioPlayer.play(UrlSource(url)); }
  }

  void _openFullScreenImage(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImage(url: url, onSave: () => _saveImage(context, url))));
  }

  Future<void> _saveImage(BuildContext context, String url) async {
    // Gardez votre logique Dio/ImageGallerySaverPlus ici
  }
}

// Widget séparé pour le plein écran pour plus de clarté
class FullScreenImage extends StatelessWidget {
  final String url;
  final VoidCallback onSave;
  const FullScreenImage({super.key, required this.url, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.download, color: Colors.white), onPressed: onSave)],
      ),
      body: Center(child: InteractiveViewer(child: Image.network(url))),
    );
  }
}