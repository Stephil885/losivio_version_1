import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../models/LiveMessage.dart'; // Assure-toi que le chemin est correct

class LiveChatSheet extends StatefulWidget {
  const LiveChatSheet({super.key});

  @override
  State<LiveChatSheet> createState() => _LiveChatSheetState();
}

class _LiveChatSheetState extends State<LiveChatSheet> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  bool showEmojiPicker = false;

  final List<LiveMessage> _messages = [
    LiveMessage(
      id: "1",
      avatar: "https://i.pravatar.cc/150?img=1",
      username: "Losivio",
      message: "Bienvenue dans le live 👑",
      role: UserRole.host,
    ),
    LiveMessage(
      id: "2",
      avatar: "https://i.pravatar.cc/150?img=2",
      username: "Mymouna",
      message: "Respectez les règles svp",
      role: UserRole.moderator,
    ),
    LiveMessage(
      id: "3",
      avatar: "https://i.pravatar.cc/150?img=3",
      username: "Admin",
      message: "Respectez tout le monde",
      role: UserRole.admin,
    ),
    LiveMessage(
      id: "4",
      avatar: "https://i.pravatar.cc/150?img=4",
      username: "Skander",
      message: "a envoyé un cadeau",
      role: UserRole.vip,
      isGift: true,
      giftIcon: "💎",
    ),
  ];

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (focusNode.hasFocus && showEmojiPicker) {
        setState(() => showEmojiPicker = false);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(LiveMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        avatar: "https://i.pravatar.cc/150?img=5",
        username: "Moi",
        message: text,
        role: UserRole.vip,
      ));
    });
    controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onEmojiSelected(Emoji emoji) {
    controller
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
  }

  Future<void> _toggleEmojiPicker() async {
    if (!showEmojiPicker) {
      focusNode.unfocus();
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() => showEmojiPicker = true);
    } else {
      focusNode.requestFocus();
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return Colors.redAccent;
      case UserRole.host: return Colors.orangeAccent;
      case UserRole.moderator: return Colors.greenAccent;
      case UserRole.vip: return Colors.purpleAccent;
      default: return Colors.white;
    }
  }

  Widget _roleBadge(UserRole role) {
    if (role == UserRole.user) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _roleColor(role),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !showEmojiPicker,
      onPopInvokedWithResult: (didPop, result) {
        if (showEmojiPicker) setState(() => showEmojiPicker = false);
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// 🔝 HANDLE BAR
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              /// 💬 MESSAGES LIST
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) => _buildMessageRow(_messages[i]),
                ),
              ),

              /// ⌨️ INPUT AREA
              _buildInputArea(),

              /// 📱 DYNAMIC SPACE (Clavier ou Emojis)
              if (showEmojiPicker)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) => _onEmojiSelected(emoji),
                    config: Config(
                      height: 256,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: EmojiViewConfig(
                        backgroundColor: Colors.black,
                        columns: 7,
                        emojiSizeMax: 28,
                        gridPadding: EdgeInsets.zero,
                        // PERFORMANCE : Limite le nombre d'emojis récents stockés
                        recentsLimit: 28,
                        // PERFORMANCE : Utilise le rendu natif Material plus rapide
                        buttonMode: ButtonMode.MATERIAL,
                        loadingIndicator: const Center(
                          child: CircularProgressIndicator(color: Colors.orangeAccent),
                        ),
                      ),
                      categoryViewConfig: const CategoryViewConfig(
                        backgroundColor: Colors.black,
                        indicatorColor: Colors.orangeAccent,
                        iconColor: Colors.white54,
                        iconColorSelected: Colors.white,
                        backspaceColor: Colors.orangeAccent,
                        dividerColor: Colors.white10,
                        // PERFORMANCE : Supprime le délai d'animation entre les catégories
                        tabIndicatorAnimDuration: Duration.zero,
                      ),
                      bottomActionBarConfig: const BottomActionBarConfig(
                        backgroundColor: Colors.black,
                        buttonColor: Colors.transparent, // Transparent pour éviter les sur-épaisseurs
                        buttonIconColor: Colors.white70,
                      ),
                      searchViewConfig: const SearchViewConfig(
                        backgroundColor: Colors.black,
                        buttonIconColor: Colors.white,
                      ),
                    ),
                  )
                )
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  height: keyboardHeight,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
              color: Colors.white,
            ),
            onPressed: _toggleEmojiPicker,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Écrire un message...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF111827),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(LiveMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(msg.avatar),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _roleBadge(msg.role),
                    Text(
                      msg.username,
                      style: TextStyle(
                        color: _roleColor(msg.role),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                msg.isGift
                    ? Row(
                        children: [
                          Text(
                            msg.message,
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 6),
                          Text(msg.giftIcon ?? "🎁", style: const TextStyle(fontSize: 16)),
                        ],
                      )
                    : Text(
                        msg.message,
                        style: const TextStyle(color: Colors.white70),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}