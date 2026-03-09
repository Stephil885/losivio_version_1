/* // frontend/lib/screens/create_live_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/live_service.dart';
import 'live_room_screen.dart';

class CreateLiveScreen extends StatefulWidget {
  const CreateLiveScreen({super.key});

  @override
  State<CreateLiveScreen> createState() => _CreateLiveScreenState();
}

class _CreateLiveScreenState extends State<CreateLiveScreen> {
  bool _isCreating = false;

  void _createLive() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final roomId = "room-${const Uuid().v4()}";

      // Création réelle de la room sur le backend
      await createRoomOnServer(roomId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Live créé ! Room ID: $roomId')),
      );

      // Redirection vers la room en affichant la vidéo locale
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveRoomScreen(roomId: roomId),
        ),
      );
    } catch (e) {
      print("Erreur création live: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur création live')),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un Live"),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _isCreating ? null : _createLive,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          child: _isCreating
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Démarrer Live", style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
 */