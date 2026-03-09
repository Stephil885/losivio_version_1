/*
// create_post.dart (ou le nom de ton fichier actuel)

import 'dart:async';
//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../forms/components/filters.dart'; // Assure-toi que CameraFilterExtension y est définie
import 'gallery_sheet.dart';
import 'media_preview.dart';
//import '../models/user.dart';
import '../models/post_media.dart';
import '../providers/user_provider.dart';
import 'startLive.dart';
import '../config/api_config.dart';

/// Dégradé utilisé pour les accents visuels
const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFEC4899), // pink-500
    Color(0xFFA855F7), // purple-500
    Color(0xFF22D3EE), // cyan-400
  ],
);

class CreatePost extends ConsumerStatefulWidget {
  final CameraController cameraController;
  final VoidCallback onSwitchCamera;
  final VoidCallback onStartLive;
  final bool isFrontCamera;

  const CreatePost({
    super.key,
    required this.cameraController,
    required this.onSwitchCamera,
    required this.onStartLive,
    required this.isFrontCamera,
  });

  @override
  ConsumerState<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends ConsumerState<CreatePost> {
  // États de la caméra et de l'upload
  bool _isRecording = false;
  bool _isFlashOn = false;
  bool _isUploading = false;
  bool _requestTranslation = false; // État pour la traduction
  bool _requestSousTitre = false; // État pour la traduction

  // Gestion des médias
  List<PostMedia> _mediaList = []; 
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();
  
  // Timer pour la vidéo
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  
  // Design & Filtres
  final Color primaryColor = Colors.white;
  final Color accentColor = const Color(0xFF5A2A6D);
  final Color highlightColor = const Color(0xFF13E7C9);
  CameraFilter _selectedFilter = CameraFilter.none;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _pageController.addListener(_updatePageIndex);
  }

  @override
  void dispose() {

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _pageController.removeListener(_updatePageIndex);
    _pageController.dispose();

    for (var media in _mediaList) {
      media.captionController.dispose();
    }

    _timer?.cancel();
    super.dispose();
  }

  void _updatePageIndex() {
    if (_pageController.hasClients && _pageController.page != null) {
      int nextIndex = _pageController.page!.round();
      if (nextIndex != _currentPageIndex) {
        if (_mediaList.isNotEmpty && _currentPageIndex < _mediaList.length) {
          _mediaList[_currentPageIndex].updateCaption();
        }
        setState(() {
          _currentPageIndex = nextIndex;
        });
      }
    }
  }

  String _getFileType(String path) {
    String extension = path.toLowerCase().split('.').last;
    return ['mp4', 'mov', 'avi', 'flv', 'wmv'].contains(extension) ? 'video' : 'image';
  }

  // --- ACTIONS ---

  Future<void> _uploadPost() async {
    
    if (_mediaList.isEmpty || _isUploading) return;

    final currentUser = ref.read(userProvider).value;
    if (currentUser == null) {
      _showSnack("⚠️ Utilisateur non identifié.");
      return;
    }
    
    _mediaList[_currentPageIndex].updateCaption(); 
    setState(() => _isUploading = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadPost));
      request.headers['x-author-id'] = currentUser.id.toString();

      String mainPostType = _getFileType(_mediaList.first.path); 
      request.fields['title'] = _mediaList.first.caption.isNotEmpty 
          ? _mediaList.first.caption 
          : "Nouveau post"; 
      request.fields['type'] = mainPostType;

      // On ajoute l'info de traduction (convertie en string pour le multipart)
      request.fields['allow_translation'] = _requestTranslation.toString();
      request.fields['allow_sous_titre'] = _requestTranslation.toString();

      for (int i = 0; i < _mediaList.length; i++) {
        final media = _mediaList[i];
        request.files.add(await http.MultipartFile.fromPath('file', media.path));
        request.fields['file_type_$i'] = media.type;
        request.fields['caption_$i'] = media.caption; 
      }

      _showSnack("🚀 Publication en cours...");
      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _clearMedia();
        _showSnack("✅ Post publié !");
        //Navigator.pop(context);
      } else {
        _showSnack("❌ Erreur serveur (${response.statusCode})");
      }
    } catch (e) {
      _showSnack("🚨 Connexion impossible");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _clearMedia() {
    setState(() {
      for (var media in _mediaList) {
        media.captionController.dispose();
      }
      _mediaList.clear();
      _currentPageIndex = 0;
    });
  }

  Future<void> _capturePhoto() async {
    try {
      if (_isFlashOn && !widget.isFrontCamera) {
        await widget.cameraController.setFlashMode(FlashMode.torch);
      }
      final XFile file = await widget.cameraController.takePicture();
      
      final newMedia = PostMedia(path: file.path, type: 'image');

      setState(() {
        _mediaList.add(newMedia);
        _currentPageIndex = _mediaList.length - 1;
        _jumpToLastPage();
      });

      if (_isFlashOn && !widget.isFrontCamera) {
        await widget.cameraController.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      debugPrint("Erreur capture photo : $e");
    }
  }

  Future<void> _startOrStopVideo() async {
    if (_isRecording) {

      final XFile file = await widget.cameraController.stopVideoRecording();

      await widget.cameraController.unlockCaptureOrientation(); // IMPORTANT

      final newMedia = PostMedia(path: file.path, type: 'video');

      setState(() {
        _isRecording = false;
        _mediaList.add(newMedia);
        _timer?.cancel();
        _currentPageIndex = _mediaList.length - 1;
        _jumpToLastPage();
      });

    } else {
      try {

        // 🔥 VERROUILLER L’ORIENTATION
        await widget.cameraController.lockCaptureOrientation(
          DeviceOrientation.portraitUp,
        );

        await widget.cameraController.startVideoRecording();

        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration =
                Duration(seconds: _recordDuration.inSeconds + 1);
          });

          if (_recordDuration.inMinutes >= 10) {
            _startOrStopVideo();
          }
        });

      } catch (e) {
        debugPrint("Erreur vidéo : $e");
      }
    }
  }

  void _jumpToLastPage() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_mediaList.length - 1);
      }
    });
  }

  Future<void> _openCustomGallery() async {
    final List<String>? selectedPaths = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.7,
        child: GallerySheet(),
      ),
    );

    if (selectedPaths != null && selectedPaths.isNotEmpty) {
      final newMediaList = selectedPaths.map((path) {
        return PostMedia(path: path, type: _getFileType(path));
      }).toList();

      setState(() {
        _mediaList = newMediaList;
        _currentPageIndex = 0;
      });
      _pageController.jumpToPage(0);
    }
  }

  void _deleteMedia(int index) {
    setState(() {
      _mediaList[index].captionController.dispose();
      _mediaList.removeAt(index);
      
      if (_mediaList.isEmpty) {
        _currentPageIndex = 0;
      } else {
        // On s'assure que l'index ne dépasse pas la nouvelle taille
        _currentPageIndex = index >= _mediaList.length ? _mediaList.length - 1 : index;
        // Utiliser animateToPage pour une transition plus fluide après suppression
        _pageController.jumpToPage(_currentPageIndex);
      }
    });
  }

  Future<void> _toggleFlash() async {
    if (widget.isFrontCamera) {
      _showSnack("⚠️ Flash non disponible en façade.");
      return;
    }
    try {
      _isFlashOn = !_isFlashOn;
      await widget.cameraController.setFlashMode(
        _isRecording || _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      _showSnack("⚠️ Flash non supporté.");
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black87,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  // --- UI COMPONENTS ---

  Widget _glassButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color ?? Colors.black38,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1.2),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _mediaList.isNotEmpty;
    final currentMedia = hasMedia ? _mediaList[_currentPageIndex] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FOND : APERCU MEDIA OU CAMERA
          Positioned.fill(
            child: hasMedia
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: _mediaList.length,
                    itemBuilder: (context, index) => MediaPreview(
                      filePath: _mediaList[index].path,
                      onDelete: () => _deleteMedia(index),
                    ),
                  )
                : ColorFiltered(
                    colorFilter: getColorFilter(_selectedFilter),
                    child: Transform.rotate(
                      angle: 0,
                      child: AspectRatio(
                        aspectRatio: widget.cameraController.value.aspectRatio,
                        child: CameraPreview(widget.cameraController),
                      ),
                    ),
                  ),
          ),
      
          // 2. INTERFACE D'ÉDITION (Si médias présents)
          if (hasMedia && currentMedia != null) ...[
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: currentMedia.captionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Ajouter une légende...",
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
      
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      "${_currentPageIndex + 1} / ${_mediaList.length}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- NOUVEAU : OPTION TRADUCTION (Uniquement pour Vidéo) ---
                      if (currentMedia.type == 'video') ...[
                        GestureDetector(
                          onTap: () => setState(() => _requestTranslation = !_requestTranslation),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _requestTranslation ? const Color(0xFF22D3EE).withOpacity(0.2) : Colors.black38,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: _requestTranslation ? const Color(0xFF22D3EE) : Colors.white24,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Pour la Traduction
                                _optionChip(
                                  icon: Icons.translate_rounded,
                                  label: "Traduire",
                                  isActive: _requestTranslation,
                                  onTap: () => setState(() => _requestTranslation = !_requestTranslation),
                                ),
                                const SizedBox(height: 8),
                                // Pour les Sous-titres
                                _optionChip(
                                  icon: Icons.subtitles_rounded,
                                  label: "Sous-titres",
                                  isActive: _requestSousTitre,
                                  onTap: () => setState(() => _requestSousTitre = !_requestSousTitre),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      _glassButton(Icons.delete_forever_rounded, () => _deleteMedia(_currentPageIndex)),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: _isUploading ? 0.5 : 1.0,
                        child: _glassButton(
                          _isUploading ? Icons.hourglass_full_rounded : Icons.send_rounded,
                          _uploadPost,
                        ),
                      ),
          const SizedBox(height: 70),
                    ],
                  ),
                ],
              ),
            ),
          ],
      
          // 3. INTERFACE CAMERA (Si pas de média ou enregistrement en cours)
          if (!hasMedia || _isRecording) ...[
            Positioned(
              top: 35,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Créer",
                  style: GoogleFonts.poppins(color: primaryColor, fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
            ),
      
            Positioned(
              top: 100,
              right: 16,
              child: Column(
                children: [
                  if (!_isRecording) _glassButton(_isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, _toggleFlash),
                  if (_isRecording)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                      child: Text(_formatTime(_recordDuration), style: GoogleFonts.orbitron(color: highlightColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  if (!_isRecording) ...[
                    const SizedBox(height: 12),
                    _glassButton(Icons.cameraswitch_rounded, widget.onSwitchCamera),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        try {
                          await widget.cameraController.dispose(); 
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (mounted) {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const StartLivePage()));
                            _showSnack("Revenez à l'accueil pour réactiver la caméra.");
                          }
                        } catch (e) { debugPrint("Erreur Live: $e"); }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text("", style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      
            // Déclencheur Principal
            if (!hasMedia)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 165), // Légèrement remonté pour le sélecteur
                  child: GestureDetector(
                    onTap: _capturePhoto,
                    onLongPress: _startOrStopVideo,
                    onLongPressUp: _isRecording ? _startOrStopVideo : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: _isRecording ? 85 : 75,
                      height: _isRecording ? 85 : 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? highlightColor : primaryColor,
                        boxShadow: [BoxShadow(color: _isRecording ? highlightColor.withOpacity(0.5) : Colors.black26, blurRadius: 20)],
                      ),
                      child: Icon(_isRecording ? Icons.stop_rounded : Icons.camera_alt_rounded, color: Colors.black, size: 34),
                    ),
                  ),
                ),
              ),
      
            if (!_isRecording && !hasMedia)
              Positioned(
                bottom: 155,
                right: 40,
                child: _glassButton(Icons.photo_library_rounded, _openCustomGallery),
              ),
      
            // --- LE NOUVEAU SÉLECTEUR DE FILTRES VISUEL ---
            if (!hasMedia)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 130,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: CameraFilter.values.length,
                    itemBuilder: (context, index) {
                      final filter = CameraFilter.values[index];
                      final isSelected = _selectedFilter == filter;
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          curve: Curves.easeOut,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // La vignette
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.white24,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: isSelected 
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)] 
                                    : [],
                                ),
                                child: ClipOval(
                                  child: ColorFiltered(
                                    colorFilter: getColorFilter(filter),
                                    child: Image.network(
                                      "https://i.pravatar.cc/150?u=${filter.index + 10}", // Image unique par filtre
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(color: Colors.white10);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Le texte
                              Text(
                                filter.name.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _optionChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF22D3EE).withOpacity(0.2) : Colors.black38,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive ? const Color(0xFF22D3EE) : Colors.white24,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? const Color(0xFF22D3EE) : Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF22D3EE) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle, color: Color(0xFF22D3EE), size: 14),
            ],
          ],
        ),
      ),
    );
  }
}
 */