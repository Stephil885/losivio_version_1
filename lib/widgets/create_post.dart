// create_post.dart (ou le nom de ton fichier actuel)

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../forms/components/filters.dart'; // fitre camera
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

    //SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
    return ['mp4', 'mov', 'avi', 'flv', 'wmv'].contains(extension)
        ? 'video'
        : 'image';
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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.uploadPost),
      );
      request.headers['x-author-id'] = currentUser.id.toString();

      String mainPostType = _getFileType(_mediaList.first.path);
      request.fields['title'] =
          _mediaList.first.caption.isNotEmpty
              ? _mediaList.first.caption
              : "Nouveau post";
      request.fields['type'] = mainPostType;

      // On ajoute l'info de traduction (convertie en string pour le multipart)
      request.fields['allow_translation'] = _requestTranslation.toString();
      request.fields['allow_sous_titre'] = _requestSousTitre.toString();

      for (int i = 0; i < _mediaList.length; i++) {
        final media = _mediaList[i];
        media.allowTranslation = _requestTranslation;
        media.allowSousTitre = _requestSousTitre;
        request.files.add(
          await http.MultipartFile.fromPath('file', media.path),
        );
        // On ajoute le nom du filtre (ex: "sepia", "vibrant")
        request.fields['filter_$i'] = media.filter.name;
        request.fields['file_type_$i'] = media.type;
        request.fields['caption_$i'] = media.caption;
        request.fields['duration_$i'] = (media.duration ?? 0).toString();
        request.fields['allow_translation_$i'] = media.allowTranslation.toString();
        request.fields['allow_sous_titre_$i'] = media.allowSousTitre.toString();
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

      //final newMedia = PostMedia(path: file.path, type: 'image');
      final newMedia = PostMedia(
        path: file.path,
        type: 'image',
        filter: _selectedFilter, // <--- On enregistre le filtre utilisé
        duration: 0,
      );

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
      // 1. ARRÊTER LE TIMER IMMÉDIATEMENT
      _timer?.cancel();
      _timer = null;

      try {
        final XFile file = await widget.cameraController.stopVideoRecording();
        await widget.cameraController.unlockCaptureOrientation();

        final newMedia = PostMedia(
          path: file.path,
          type: 'video',
          filter: _selectedFilter,
        );

        setState(() {
          _isRecording = false;
          _mediaList.add(newMedia);
          _currentPageIndex = _mediaList.length - 1;
          _jumpToLastPage();
        });
      } catch (e) {
        debugPrint("Erreur arrêt vidéo : $e");
      }
    } else {
      // ... reste du code pour démarrer l'enregistrement ...
      try {
        // (vos étapes 1, 2, 3...)
        await widget.cameraController.prepareForVideoRecording();
        await widget.cameraController.startVideoRecording();

        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration = Duration(seconds: _recordDuration.inSeconds + 1);
          });
          
          if (_recordDuration.inSeconds >= 300) {
            _startOrStopVideo(); 
          }
        });
      } catch (e) {
        debugPrint("Erreur démarrage vidéo : $e");
        _timer?.cancel(); // Sécurité
        await widget.cameraController.unlockCaptureOrientation();
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
      List<PostMedia> validMedia = [];

      // On affiche un loader si nécessaire car l'analyse peut prendre un peu de temps
      _showSnack("Analyse des médias...");

      for (String path in selectedPaths) {
        final type = _getFileType(path);
        int durationInSeconds = 0;
        if (type == 'video') {
          // --- VÉRIFICATION DE LA DURÉE ---
          //final controller = VideoPlayerController.networkUrl(Uri.parse(path)); // Pour fichiers locaux ou distants
          // Note: Sur certains systèmes, il vaut mieux utiliser VideoPlayerController.file(File(path))
          final controller = VideoPlayerController.file(File(path));
          
          try {
            await controller.initialize();
            final duration = controller.value.duration;
            durationInSeconds = duration.inSeconds;
            await controller.dispose();

            if (duration.inSeconds > 300) {
              _showSnack("⚠️ Une vidéo dépasse 90s et a été retirée.");
              continue; // On saute cette vidéo
            }
          } catch (e) {
            debugPrint("Erreur analyse vidéo: $e");
            continue;
          }
        }

        // Si c'est une image ou une vidéo valide
        validMedia.add(PostMedia(
          path: path,
          type: type,
          filter: CameraFilter.none,
          duration: durationInSeconds,
        ));
      }

      if (validMedia.isNotEmpty) {
        setState(() {
          _mediaList = validMedia;
          _currentPageIndex = 0;
        });
        _pageController.jumpToPage(0);
      }
    }
  }

  void _deleteMedia(int index) {
    setState(() {
      // 1. On récupère le média et on dispose son controller proprement
      final mediaToRemove = _mediaList[index];
      mediaToRemove.captionController.dispose(); 
      
      // 2. On supprime de la liste
      _mediaList.removeAt(index);

      if (_mediaList.isEmpty) {
        _currentPageIndex = 0;
      } else {
        _currentPageIndex = index >= _mediaList.length ? _mediaList.length - 1 : index;
        // Utilise jumpToPage après le rendu pour éviter les index out of bounds
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_currentPageIndex);
          }
        });
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
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FOND : APERCU OU CAMERA
          Positioned.fill(
            child:
                hasMedia
                    ? // Dans la section 1. FOND : APERCU OU CAMERA
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _mediaList.length,
                      itemBuilder: (context, index) {
                        final media = _mediaList[index];
                        return ColorFiltered(
                          colorFilter: getColorFilter(media.filter),
                          child: MediaPreview(
                            filePath: media.path,
                            onDelete: () => _deleteMedia(index),
                          ),
                        );
                      },
                    )
                    : Center(
                        child: ColorFiltered(
                          colorFilter: getColorFilter(_selectedFilter),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // On calcule le scale pour que la caméra remplisse l'écran sans déformation
                              final size = constraints.biggest;
                              var scale = size.aspectRatio * widget.cameraController.value.aspectRatio;
                              if (scale < 1) scale = 1 / scale;

                              return Transform.scale(
                                scale: scale,
                                child: Center(
                                  child: CameraPreview(widget.cameraController),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),

          // 2. OVERLAY GRADIENT (Pour que le texte blanc ressorte toujours)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          // 3. BARRE SUPÉRIEURE (Titre et Fermer)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  hasMedia ? "ÉDITION" : "CRÉER",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 40), // Équilibre visuel
              ],
            ),
          ),

          // 4. INTERFACE D'ÉDITION (Si médias présents)
          if (hasMedia && currentMedia != null) ...[
            // Légende en bas, juste au dessus des boutons
            Positioned(
              bottom: 180,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: currentMedia.captionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Écrire une légende...",
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Actions d'édition (Traduire, Supprimer, Envoyer)
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  if (currentMedia.type == 'video') ...[
                    _smallActionBtn(
                      _requestTranslation
                          ? Icons.translate
                          : Icons.translate_outlined,
                      () => setState(
                        () => _requestTranslation = !_requestTranslation,
                      ),
                      active: _requestTranslation,
                    ),
                    const SizedBox(width: 10),
                    _smallActionBtn(
                      _requestSousTitre
                          ? Icons.subtitles
                          : Icons.subtitles_outlined,
                      () => setState(
                        () => _requestSousTitre = !_requestSousTitre,
                      ),
                      active: _requestSousTitre,
                    ),
                  ],
                  const Spacer(),
                  _smallActionBtn(
                    Icons.delete_outline,
                    () => _deleteMedia(_currentPageIndex),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    // Si _isUploading est vrai, on passe null à onTap pour désactiver le bouton
                    onTap: _isUploading ? null : _uploadPost, 
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        // On peut changer l'opacité du dégradé si on upload pour montrer que c'est désactivé
                        gradient: _isUploading 
                            ? LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade700]) 
                            : kAccentGradient,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: _isUploading 
                        ? const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(
                              strokeWidth: 2, 
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Publier",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 5. INTERFACE CAMERA
          if (!hasMedia || _isRecording) ...[
            // Barre latérale droite
            Positioned(
              right: 15,
              top: 120,
              child: Column(
                children: [
                  _sideIconButton(
                    _isFlashOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    "Flash",
                    _toggleFlash,
                  ),
                  _sideIconButton(
                    Icons.cameraswitch_rounded,
                    "Tourner",
                    widget.onSwitchCamera,
                  ),
                  _sideIconButton(
                    Icons.live_tv_rounded,
                    "Live",
                    widget.onStartLive,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),

            // Timer (Vidéo)
            if (_isRecording)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatTime(_recordDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Déclencheur et Galerie
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Sélecteur de filtres (Vignettes)
                  SizedBox(
                    height: 100, // Ajusté pour laisser de la place au texte
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: CameraFilter.values.length,
                      itemBuilder: (context, index) {
                        final filter = CameraFilter.values[index];
                        final isSelected = _selectedFilter == filter;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                width: isSelected ? 65 : 55,
                                height: isSelected ? 65 : 55,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.white24,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: buildFilterPreview(
                                    filter,
                                  ), // Utilise ta fonction de preview déjà définie !
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                filter
                                    .label, // <-- Correction ici : .label et non .name
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.white60,
                                  fontSize: 11,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bouton central + Galerie
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _glassButton(
                        Icons.photo_library_outlined,
                        _openCustomGallery,
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_isRecording) {
                            _startOrStopVideo();
                          } else {
                            _capturePhoto();
                          }
                        },
                        onLongPress: _isRecording ? null : _startOrStopVideo,
                        // Retirer onLongPressUp si on veut que la vidéo continue même si on lâche le doigt
                        // Ou le laisser si vous voulez le comportement "à la Instagram"
                        onLongPressUp: () {
                          if (_isRecording) {
                            _startOrStopVideo();
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _isRecording ? 40 : 70,
                              height: _isRecording ? 40 : 70,
                              decoration: BoxDecoration(
                                color: _isRecording ? Colors.red : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  _isRecording ? 8 : 35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 50), // Pour centrer le bouton
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Nouveaux Composants de style ---

  Widget _sideIconButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallActionBtn(
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? highlightColor : Colors.white12,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: active ? Colors.black : Colors.white,
          size: 22,
        ),
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
          color:
              isActive
                  ? const Color(0xFF22D3EE).withOpacity(0.2)
                  : Colors.black38,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive ? const Color(0xFF22D3EE) : Colors.white24,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF22D3EE) : Colors.white,
              size: 18,
            ),
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
              const Icon(
                Icons.check_circle,
                color: Color(0xFF22D3EE),
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
