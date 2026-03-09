// lib/screens/chat_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../widgets/chat_bubble.dart';
import '../redux/app_state.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final int friendId;
  final String friendName;
  final String? friendAvatar;

  const ChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // 🔥 AJOUTÉ : La variable pour gérer l'abonnement WebSocket
  StreamSubscription? _wsSubscription; 

  Map<String, dynamic>? _replyMessage;

  bool _showSendButton = false;
  bool _showEmojiPicker = false;
  bool _isStickerMode = false;

  final ChatService _chatService = ChatService();
  List<ChatMessage> _messages = []; 
  bool _isLoading = true;

  late AudioRecorder _audioRecorder;
  Timer? _timer;
  int _recordDuration = 0;
  bool _isRecording = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();

    // On lance l'écoute
    _initWebSocketListener();

    _messageController.addListener(() {
      if (mounted) {
        setState(() {
          _showSendButton = _messageController.text.trim().isNotEmpty;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel(); // 🔥 On arrête d'écouter le WebSocket proprement
    _audioRecorder.dispose();
    _timer?.cancel();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initWebSocketListener() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    final currentUserId = int.parse(store.state.user!.id.toString());

    // On écoute le service WebSocket
    _wsSubscription = webSocketService.messages.listen((incomingData) {
      // 1. On transforme le JSON brut en objet ChatMessage
      final newMessage = _mapIncomingMessage(incomingData, currentUserId);

      // 2. FILTRAGE : On n'ajoute le message que s'il vient de l'ami actuel 
      bool isFromCurrentFriend = newMessage.senderId == widget.friendId;
      
      // Note: On pourrait aussi ajouter "|| newMessage.isMe" si on veut voir nos propres messages 
      // arriver via le socket (utile si on est connecté sur deux téléphones en même temps).
      
      if (isFromCurrentFriend && mounted) {
        setState(() {
          // On l'insère au début car ton ListView est en 'reverse: true'
          _messages.insert(0, newMessage);
        });
      }
    });
  }

  // 🔥 DÉPLACÉ ICI (à l'intérieur de la classe) pour avoir accès à 'context'
  ChatMessage _mapIncomingMessage(Map<String, dynamic> json, int currentUserId) {
    // On utilise l'URL de ton serveur pour les médias
    const String serverUrl = "http://192.168.2.88:9010";

    // Extraction des médias
    List attachments = json['attachments'] ?? [];
    String? imagePath;
    if (attachments.isNotEmpty) {
      final firstImage = attachments.firstWhere((a) => a['type'] == 'image', orElse: () => null);
      if (firstImage != null) imagePath = "$serverUrl${firstImage['url']}";
    }

    String? audioPath = json['audioVocal_path'] != null 
        ? "$serverUrl${json['audioVocal_path']}" 
        : null;

    return ChatMessage(
      id: json['id'],
      text: json['message'] ?? "",
      isMe: json['sender_id'].toString() == currentUserId.toString(),
      // 'context' est maintenant accessible ici
      time: TimeOfDay.now().format(context), 
      isAudio: audioPath != null,
      audioPath: audioPath,
      isImage: imagePath != null,
      imagePath: imagePath,
      parentMessageId: json['parent_message_id'],
      replyTo: json['replyTo'],
      senderId: json['sender_id'], 
      receiverId: json['receiver_id'],
    );
  }

  // --- CHARGEMENT ---

  Future<void> _loadMessages() async {
    try {
      final store = StoreProvider.of<AppState>(context, listen: false);
      final user = store.state.user;
      if (user == null) return;
      
      final currentUserId = int.parse(user!.id.toString());

      final fetchedMessages = await _chatService.getMessages(
        currentUserId, 
        widget.friendId
      );

      if (mounted) {
        setState(() {
          _messages = fetchedMessages.reversed.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur de chargement: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIQUE D'ENVOI (BACKEND) ---

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final store = StoreProvider.of<AppState>(context, listen: false);
    final user = store.state.user;
    final currentUserId = int.parse(user!.id.toString());
    final textToSend = _messageController.text;
    final parentId = _replyToId;

    _messageController.clear();
    setState(() => _replyMessage = null);

    final newMessage = await _chatService.sendMessage(
      senderId: currentUserId,
      receiverId: widget.friendId,
      text: textToSend,
      parentMessageId: parentId,
    );

    if (newMessage != null && mounted) {
      setState(() => _messages.insert(0, newMessage));
    }
  }

  void _sendAudioMessage(String path, int durationInSeconds) async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    final user = store.state.user;
    final currentUserId = int.parse(user!.id.toString());

    final newMessage = await _chatService.sendVoiceMessage(
      senderId: currentUserId,
      receiverId: widget.friendId,
      filePath: path,
      parentMessageId: _replyToId,
    );

    if (newMessage != null && mounted) {
      setState(() {
        _messages.insert(0, newMessage);
        _replyMessage = null;
      });
    }
  }

  void _sendMediaMessage(List<File> files) async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    final user = store.state.user;
    final currentUserId = int.parse(user!.id.toString());

    final newMessage = await _chatService.sendMessage(
      senderId: currentUserId,
      receiverId: widget.friendId,
      files: files,
      parentMessageId: _replyToId,
    );

    if (newMessage != null && mounted) {
      setState(() {
        _messages.insert(0, newMessage);
        _replyMessage = null;
      });
    }
  }

  // --- LOGIQUE MÉDIA (PICKERS) ---

  void _sendSticker(String path) {
    _messageController.text = "[sticker]:$path";
    _sendMessage();
    setState(() => _showEmojiPicker = false);
  }

  Future<void> _pickFromGallery() async {
    final List<XFile> media = await _picker.pickMultipleMedia();
    if (media.isNotEmpty) {
      _sendMediaMessage(media.map((m) => File(m.path)).toList());
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) _sendMediaMessage([File(image.path)]);
  }

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      _sendAudioMessage(result.files.single.path!, 0);
    }
  }

  // --- AUDIO RECORDER ---

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
        _showEmojiPicker = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _recordDuration++));
    }
  }

  Future<void> _stopRecording({bool send = true}) async {
    final path = await _audioRecorder.stop();
    _timer?.cancel();
    setState(() => _isRecording = false);
    if (send && path != null) _sendAudioMessage(path, _recordDuration);
  }

  // --- HELPERS ---

  int? get _replyToId => _replyMessage != null ? _replyMessage!['id'] : null;
  String _formatDuration(int seconds) => "${(seconds / 60).floor()}:${(seconds % 60).toString().padLeft(2, '0')}";
  bool get _hasAvatar => widget.friendAvatar != null && widget.friendAvatar!.isNotEmpty;

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)))
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return ChatBubble(
                      id: msg.id,
                      message: msg.text,
                      isMe: msg.isMe,
                      time: msg.time,
                      isAudio: msg.isAudio,
                      audioPath: msg.audioPath,
                      isImage: msg.isImage,
                      imagePath: msg.imagePath,
                      isVideo: msg.isVideo,
                      videoPath: msg.videoPath,
                      replyTo: msg.replyTo,
                      onReply: () => setState(() => _replyMessage = {
                        'id': msg.id,
                        'text': msg.text,
                        'isMe': msg.isMe,
                        'isAudio': msg.isAudio,
                      }),
                    );
                  },
                ),
          ),
          _buildBottomArea(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      iconTheme: const IconThemeData(color: Colors.black),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: _hasAvatar ? NetworkImage(widget.friendAvatar!) : null,
            backgroundColor: _hasAvatar ? Colors.transparent : const Color(0xFFA855F7),
            child: _hasAvatar ? null : Text(widget.friendName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Text(widget.friendName, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.videocam_rounded), onPressed: () {}),
        IconButton(icon: const Icon(Icons.call), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text("Voir le profil"),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text("Bloquer"),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text("Supprimer la conversation"),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
        }),
      ],
    );
  }

  Widget _buildBottomArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyMessage != null) _buildReplyPreview(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
            ],
          ),
          child: SafeArea(
            bottom: !_showEmojiPicker, 
            child: _isRecording ? _buildRecordingUI() : _buildTextInputUI(),
          ),
        ),
        if (_showEmojiPicker)
          SizedBox(
            height: 300,
            child: Column(
              children: [
                _buildPickerTabs(),
                Expanded(
                  child: _isStickerMode ? _buildStickerGrid() : _buildEmojiPicker(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextInputUI() {
    return Row(
      children: [
        IconButton(
          icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined, color: const Color(0xFFA855F7)),
          onPressed: () {
            if (_showEmojiPicker) {
              _focusNode.requestFocus();
            } else {
              _focusNode.unfocus();
              setState(() => _showEmojiPicker = true);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
          onPressed: () => _showAttachmentOptions(),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)),
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: const InputDecoration(hintText: "Écrire un message...", border: InputBorder.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildSendOrMicButton(),
      ],
    );
  }

  Widget _buildPickerTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabButton(Icons.emoji_emotions, "Emojis", !_isStickerMode),
          _buildTabButton(Icons.sticky_note_2, "Stickers", _isStickerMode),
        ],
      ),
    );
  }

  Widget _buildTabButton(IconData icon, String label, bool isSelected) {
    return TextButton.icon(
      onPressed: () => setState(() => _isStickerMode = label == "Stickers"),
      icon: Icon(icon, color: isSelected ? const Color(0xFFA855F7) : Colors.grey),
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.grey)),
    );
  }

  Widget _buildEmojiPicker() {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) => _messageController.text += emoji.emoji,
      config: Config(
        height: 256,
        emojiViewConfig: EmojiViewConfig(
          backgroundColor: Colors.white,
          columns: 7,
          loadingIndicator: const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7))),
        ),
      ),
    );
  }

  Widget _buildStickerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: 8,
      itemBuilder: (context, index) {
        String path = "assets/stickers/sticker_$index.png";
        return GestureDetector(
          onTap: () => _sendSticker(path),
          child: Image.asset(path),
        );
      },
    );
  }

  Widget _buildSendOrMicButton() {
    return GestureDetector(
      onTap: _showSendButton ? _sendMessage : _startRecording,
      child: Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF9333EA)]),
          shape: BoxShape.circle,
        ),
        child: Icon(_showSendButton ? Icons.send_rounded : Icons.mic_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => _stopRecording(send: false)),
        const Spacer(),
        Text("Enregistrement ${_formatDuration(_recordDuration)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        const Spacer(),
        GestureDetector(
          onTap: () => _stopRecording(send: true),
          child: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(color: Color(0xFFA855F7), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(color: Colors.grey.shade50, border: const Border(left: BorderSide(color: Color(0xFFA855F7), width: 4))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_replyMessage!['isMe'] ? "Vous" : widget.friendName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA855F7))),
                Text(_replyMessage!['isAudio'] == true ? "🎵 Message vocal" : _replyMessage!['text'], maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _replyMessage = null)),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAttachmentItem(Icons.collections, "Galerie", Colors.blue, () {
              Navigator.pop(context);
              _pickFromGallery();
            }),
            _buildAttachmentItem(Icons.audiotrack, "Musique", Colors.amber, () {
              Navigator.pop(context);
              _pickAudioFile();
            }),
            _buildAttachmentItem(Icons.camera_alt, "Caméra", Colors.pink, () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            }),
            _buildAttachmentItem(Icons.sticky_note_2, "Stickers", Colors.orange, () {
              Navigator.pop(context);
              setState(() {
                _showEmojiPicker = true;
                _isStickerMode = true;
                _focusNode.unfocus();
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 30)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}