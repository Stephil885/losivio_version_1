// lib/screens/chat_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:losivio/config/api_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter/foundation.dart' as foundation;

import '../widgets/chat_bubble.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import '../models/chat_model.dart';
import '../screens/profile_screen.dart';
import '../providers/user_provider.dart';
import '../config/api_config.dart';

// --- CONFIGURATION DESIGN ---
const Color kBackgroundColor = Color(0xFF0F172A);
const Color kSurfaceColor = Color(0xFF1E293B);
const Color kInputColor = Color(0xFF334155);

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

class ChatScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _wsSubscription;
  Map<String, dynamic>? _replyMessage;

  bool _showSendButton = false;
  bool _showEmojiPicker = false;
  bool _isStickerMode = false;
  bool _isLoading = true;
  bool _isRecording = false;

  final ChatService _chatService = ChatService();
  List<ChatMessage> _messages = [];

  late AudioRecorder _audioRecorder;
  Timer? _timer;
  int _recordDuration = 0;

  final ImagePicker _picker = ImagePicker();

  int? get _currentUserId => ref.read(userProvider).value?.id;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _initWebSocketListener();

    _messageController.addListener(() {
      if (mounted) {
        setState(() => _showSendButton = _messageController.text.trim().isNotEmpty);
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) setState(() => _showEmojiPicker = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessages());
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    webSocketService.disconnect();
    _audioRecorder.dispose();
    _timer?.cancel();
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- WEBSOCKET & LOGIC ----------------

  void _initWebSocketListener() {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    webSocketService.connect(currentUserId);
    _wsSubscription = webSocketService.messages.listen((incomingData) {
      try {
        final newMessage = ChatMessage.fromMap(incomingData, currentUserId, ApiConfig.avatarUrl);
        final friendId = widget.friendId;

        bool belongsToConversation =
            (newMessage.senderId == friendId && newMessage.receiverId == currentUserId) ||
                (newMessage.senderId == currentUserId && newMessage.receiverId == friendId);

        if (belongsToConversation && mounted) {
          setState(() {
            if (!_messages.any((m) => m.id == newMessage.id)) {
              _messages.insert(0, newMessage);
              _scrollToBottom();
            }
          });
        }
      } catch (e) {
        debugPrint("❌ WS parse error: $e");
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _loadMessages() async {
    try {
      final uid = _currentUserId;
      if (uid == null) return;
      final fetched = await _chatService.getMessages(uid, widget.friendId);
      if (mounted) {
        setState(() {
          _messages = fetched.reversed.toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- ACTIONS ----------------

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final uid = _currentUserId;
    if (uid == null) return;

    final text = _messageController.text;
    final parentId = _replyToId;
    _messageController.clear();
    setState(() => _replyMessage = null);

    final msg = await _chatService.sendMessage(
      senderId: uid,
      receiverId: widget.friendId,
      text: text,
      parentMessageId: parentId,
    );
    _handleSentMessage(msg);
  }

  void _sendAudioMessage(String path, int duration) async {
    final uid = _currentUserId;
    if (uid == null) return;
    final msg = await _chatService.sendVoiceMessage(
      senderId: uid,
      receiverId: widget.friendId,
      filePath: path,
      parentMessageId: _replyToId,
    );
    _handleSentMessage(msg);
  }

  void _sendMediaMessage(List<File> files) async {
    final uid = _currentUserId;
    if (uid == null) return;
    final msg = await _chatService.sendMessage(
      senderId: uid,
      receiverId: widget.friendId,
      files: files,
      parentMessageId: _replyToId,
    );
    _handleSentMessage(msg);
  }

  void _handleSentMessage(ChatMessage? message) {
    if (message != null && mounted) {
      setState(() {
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.insert(0, message);
        }
        _replyMessage = null;
      });
    }
  }

  // ---------------- PICKERS & AUDIO ----------------

  void _sendSticker(String path) {
    _messageController.text = "[sticker]:$path";
    _sendMessage();
    setState(() => _showEmojiPicker = false);
  }

  Future<void> _pickFromGallery() async {
    final media = await _picker.pickMultipleMedia();
    if (media.isNotEmpty) _sendMediaMessage(media.map((m) => File(m.path)).toList());
  }

  Future<void> _pickImage(ImageSource source) async {
    final img = await _picker.pickImage(source: source);
    if (img != null) _sendMediaMessage([File(img.path)]);
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      _sendAudioMessage(result.files.single.path!, 0);
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
        _showEmojiPicker = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _recordDuration++));
    }
  }

  Future<void> _stopRecording({bool send = true}) async {
    if (!_isRecording) return;
    final path = await _audioRecorder.stop();
    _timer?.cancel();
    setState(() => _isRecording = false);
    if (send && path != null) {
      _sendAudioMessage(path, _recordDuration);
    } else if (path != null) {
      File(path).delete().ignore();
    }
  }

  int? get _replyToId => _replyMessage?['id'];
  bool get _hasAvatar => widget.friendAvatar != null && widget.friendAvatar!.isNotEmpty;
  String _formatDuration(int s) => "${(s / 60).floor()}:${(s % 60).toString().padLeft(2, '0')}";

  // ---------------- UI BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[i];
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
                          'isImage': msg.isImage,
                          'isVideo': msg.isVideo,
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
      backgroundColor: kSurfaceColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: InkWell(
        onTap: () => _showFriendProfile(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: _hasAvatar ? NetworkImage('${widget.friendAvatar!}') : null,
              backgroundColor: Colors.white24,
              child: !_hasAvatar ? Text(widget.friendName[0].toUpperCase(), style: const TextStyle(color: Colors.white)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.friendName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Text("En ligne", style: TextStyle(color: Color(0xFF22D3EE), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.white70), onPressed: () {}),
        IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.white70), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert, color: Colors.white70), onPressed: _showOptionsMenu),
      ],
    );
  }

  Widget _buildBottomArea() {
    return Container(
      decoration: const BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyMessage != null) _buildReplyPreview(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SafeArea(
              top: false,
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
                  Expanded(child: _isStickerMode ? _buildStickerGrid() : _buildEmojiPicker()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    String previewText = _replyMessage!['text'] ?? "";
    if (_replyMessage!['isAudio'] == true) previewText = "🎵 Message vocal";
    else if (_replyMessage!['isImage'] == true) previewText = "📷 Photo";
    else if (_replyMessage!['isVideo'] == true) previewText = "🎥 Vidéo";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: const Border(left: BorderSide(color: Color(0xFFEC4899), width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyMessage!['isMe'] ? "Vous" : widget.friendName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEC4899), fontSize: 12)
                ),
                Text(previewText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.white38), onPressed: () => setState(() => _replyMessage = null)),
        ],
      ),
    );
  }

  Widget _buildTextInputUI() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined, color: Colors.white60),
          onPressed: () {
            setState(() {
              if (_showEmojiPicker) { _focusNode.requestFocus(); } 
              else { _focusNode.unfocus(); _showEmojiPicker = true; }
            });
          },
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: kInputColor, borderRadius: BorderRadius.circular(24)),
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              maxLines: 5,
              minLines: 1,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Écrire un message...",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (!_showSendButton)
          IconButton(icon: const Icon(Icons.attach_file, color: Colors.white60), onPressed: _showAttachmentOptions),
        
        GestureDetector(
          onTap: _showSendButton ? _sendMessage : _startRecording,
          child: Container(
            height: 48, width: 48,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: kAccentGradient),
            child: Icon(_showSendButton ? Icons.send_rounded : Icons.mic_none_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFEC4899)), onPressed: () => _stopRecording(send: false)),
        const SizedBox(width: 10),
        const Icon(Icons.circle, color: Colors.red, size: 12),
        const SizedBox(width: 8),
        Text(_formatDuration(_recordDuration), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const Spacer(),
        const Text("Enregistrement...", style: TextStyle(color: Colors.white38)),
        const Spacer(),
        GestureDetector(
          onTap: () => _stopRecording(send: true),
          child: Container(
            height: 48, width: 48,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: kAccentGradient),
            child: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF22D3EE)),
              title: const Text("Voir le profil", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _showFriendProfile(); },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Color(0xFFEC4899)),
              title: const Text("Bloquer l'utilisateur", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text("Supprimer la conversation", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); setState(() => _messages.clear()); },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFriendProfile() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProfileScreen(userId: widget.friendId, userName: widget.friendName, avatar: widget.friendAvatar),
    ));
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAttachmentItem(Icons.image_outlined, "Galerie", const Color(0xFFA855F7), _pickFromGallery),
            _buildAttachmentItem(Icons.camera_alt_outlined, "Appareil", const Color(0xFFEC4899), () => _pickImage(ImageSource.camera)),
            _buildAttachmentItem(Icons.audiotrack_outlined, "Audio", const Color(0xFF22D3EE), _pickAudioFile),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: () { Navigator.pop(context); onTap(); },
          icon: Icon(icon, color: color),
          style: IconButton.styleFrom(backgroundColor: color.withOpacity(0.1), padding: const EdgeInsets.all(16)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildPickerTabs() {
    return Container(
      color: kSurfaceColor,
      child: Row(
        children: [
          Expanded(child: _buildTabButton(Icons.emoji_emotions_outlined, "Emojis", !_isStickerMode)),
          Expanded(child: _buildTabButton(Icons.sticky_note_2_outlined, "Stickers", _isStickerMode)),
        ],
      ),
    );
  }

  Widget _buildTabButton(IconData icon, String label, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _isStickerMode = label == "Stickers"),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: isSelected ? const Border(bottom: BorderSide(color: Color(0xFFA855F7), width: 2)) : null),
        child: Icon(icon, color: isSelected ? const Color(0xFFA855F7) : Colors.white24),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        setState(() {
          _messageController.text += emoji.emoji;
          _showSendButton = true;
        });
      },
      config: Config(
        height: 256,
        checkPlatformCompatibility: true,
        // En V2, on utilise souvent "emojiViewConfig" (complet) 
        // ou des paramètres directs selon la sous-version.
        // Tentons la syntaxe la plus stable pour votre cas :
        emojiViewConfig: EmojiViewConfig(
          backgroundColor: kBackgroundColor,
          columns: 7,
          emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.2 : 1.0),
        ),
        categoryViewConfig: const CategoryViewConfig(
          backgroundColor: kSurfaceColor,
          indicatorColor: Color(0xFFA855F7),
          iconColorSelected: Color(0xFFA855F7),
          backspaceColor: Color(0xFFA855F7),
        ),
        skinToneConfig: const SkinToneConfig(
          enabled: true,
          indicatorColor: Colors.grey,
        ),
        
        /* recentTabConfig: const recentTabConfig(
          recentsLimit: 28,
          noRecents: Text(
            'Aucun récent',
            style: TextStyle(fontSize: 20, color: Colors.black26),
            textAlign: TextAlign.center,
          ),
        ), */
      ),
    );
  }

  Widget _buildStickerGrid() {
    return Container(
      color: kBackgroundColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 16, crossAxisSpacing: 16),
        itemCount: 12,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendSticker("sticker_$index.png"),
            child: Container(
              decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.face_retouching_natural, size: 32, color: Colors.white24),
            ),
          );
        },
      ),
    );
  }
}