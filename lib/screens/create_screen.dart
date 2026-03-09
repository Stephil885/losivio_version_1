// frontend/lib/screens/create_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../widgets/create_post.dart';
// import '../screens/create_live_screen.dart'; // À décommenter si besoin

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFrontCamera = true;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    // On force l'orientation portrait au niveau de l'UI Flutter immédiatement
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initializeCamera();
  }

  Future<void> _initializeCamera({CameraLensDirection direction = CameraLensDirection.front}) async {
    try {
      _cameras ??= await availableCameras();
      
      final selectedCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == direction,
        orElse: () => _cameras!.first,
      );

      // Création du contrôleur
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.ultraHigh,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg, // Plus stable pour les filtres Android
      );

      _cameraController = controller;

      // Initialisation
      await controller.initialize();

      // VERROUILLAGE CRITIQUE : Empêche le capteur de pivoter en interne
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      
      // Flash par défaut
      await controller.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isFrontCamera = direction == CameraLensDirection.front;
        });
      }
    } catch (e) {
      debugPrint("Erreur initialisation caméra : $e");
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameraController == null || _cameras == null) return;
    
    final newDirection = _isFrontCamera 
        ? CameraLensDirection.back 
        : CameraLensDirection.front;

    setState(() => _isCameraInitialized = false);
    
    // On nettoie l'ancien contrôleur avant d'en créer un nouveau
    await _cameraController?.dispose();
    await _initializeCamera(direction: newDirection);
  }

  Future<void> _handleLiveLaunch() async {
    setState(() => _isCameraInitialized = false);

    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

    if (!mounted) return;

    // Logique de navigation vers le Live (à décommenter)
    /* await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateLiveScreen()),
    ); 
    */

    // Réinitialisation au retour du Live
    await _initializeCamera(
      direction: _isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back
    );
  }

  @override
  void dispose() {
    // On libère la caméra
    _cameraController?.dispose();
    // On peut remettre l'orientation libre ici si l'app le permet ailleurs
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si la caméra n'est pas prête, on affiche un loader noir (plus propre)
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      // Note : On ne met plus de CameraPreview ici ! 
      // C'est CreatePost qui va gérer l'affichage dans son propre build.
      body: CreatePost(
        cameraController: _cameraController!,
        onSwitchCamera: _toggleCamera,
        isFrontCamera: _isFrontCamera,
        onStartLive: _handleLiveLaunch,
      ),
    );
  }
}