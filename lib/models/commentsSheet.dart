import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../services/post_service.dart';
import '../config/api_config.dart';


/* -------------------------------------------------------------------------- */
/* COMMENTS SHEET (CONNECTÉ AU BACKEND)                                       */
/* -------------------------------------------------------------------------- */

class CommentsSheet extends StatefulWidget {
  final int postId;
  final int? currentUserId; // Nullable pour les visiteurs
  final int postUserId;     // ID de l'auteur du post (pour le badge Auteur)

  const CommentsSheet({
    super.key,
    required this.postId,
    this.currentUserId,
    required this.postUserId,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  
  // --- ÉTATS ---
  List<CommentModel> _comments = [];
  bool _isLoading = true;   // Chargement initial
  bool _isSending = false;  // Envoi d'un message

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- LOGIQUE API ---

  Future<void> _fetchComments() async {
    // On appelle le service connecté à ton Node.js
    final data = await PostService.getComments(widget.postId);
    if (mounted) {
      setState(() {
        _comments = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.currentUserId == null) return;

    setState(() => _isSending = true);

    // Envoi au backend
    final success = await PostService.addComment(
      postId: widget.postId,
      userId: widget.currentUserId!,
      content: text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      
      if (success) {
        _controller.clear();
        FocusScope.of(context).unfocus(); // Fermer le clavier
        _fetchComments(); // Recharger la liste pour voir le message
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi du commentaire")),
        );
      }
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F172A).withOpacity(0.9), // slate-900
                    const Color(0xFF1E293B).withOpacity(0.85), // slate-800
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                      : _comments.isEmpty 
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _comments.length,
                              itemBuilder: (_, index) {
                                final comment = _comments[index];
                                final bool isCreator = comment.userId == widget.postUserId;
                                final bool isMe = comment.userId == widget.currentUserId;

                                return _CommentItem(
                                  commentModel: comment,
                                  isAuthor: isCreator,
                                  isMe: isMe,
                                );
                              },
                            ),
                  ),
                  _buildInputBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            "Aucun commentaire.\nSoyez le premier !",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 45,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Commentaires (${_comments.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- INPUT BAR ---
  Widget _buildInputBar() {
    // Si pas connecté, on cache l'input ou on met un message
    if (widget.currentUserId == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Text("Connectez-vous pour participer", style: TextStyle(color: Colors.white54)),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: Row(
            children: [
              // Avatar utilisateur actuel (Placeholder)
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white10,
                child: Icon(Icons.person, color: Colors.white30, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: _isSending 
                  ? const SizedBox(
                      width: 20, height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)
                    )
                  : const Icon(Icons.send_rounded, color: Colors.cyanAccent),
                onPressed: _isSending ? null : _sendComment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* COMMENT ITEM (Dynamique)                                                   */
/* -------------------------------------------------------------------------- */

class _CommentItem extends StatelessWidget {
  final CommentModel commentModel;
  final bool isAuthor; 
  final bool isMe;     

  const _CommentItem({
    required this.commentModel,
    this.isAuthor = false,
    this.isMe = false,
  });

  // Helper pour afficher la date relative
  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return "${diff.inDays}j";
    if (diff.inHours > 0) return "${diff.inHours}h";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "À l'instant";
  }

  // Helper pour l'image (si le backend renvoie un chemin relatif)
  String _getAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    // Remplace par l'IP de ton serveur si nécessaire, ou gère le dans le Model
    //return "http://192.168.2.88:9010/$path"; 
    return '${ApiConfig.avatarUrl}/$path'; 
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _getAvatarUrl(commentModel.profilePicture);
    final dateStr = _formatDate(commentModel.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AVATAR
          CircleAvatar(
            radius: 16, 
            backgroundColor: Colors.white12,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 18, color: Colors.white54) : null,
          ),
          const SizedBox(width: 12),
          
          // CONTENU
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      commentModel.username,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9), // Un peu plus clair pour la lisibilité
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isAuthor) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFA855F7)]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AUTEUR',
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  commentModel.content,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Répondre", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                    // Tu pourrais ajouter les likes de commentaire ici plus tard
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // OPTION ICON
          _CommentOptionsIcon(isMe: isMe),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* OPTIONS ICON                                                               */
/* -------------------------------------------------------------------------- */

class _CommentOptionsIcon extends StatelessWidget {
  final bool isMe;
  const _CommentOptionsIcon({required this.isMe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: const Icon(Icons.more_horiz, color: Colors.white38, size: 18),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container( // On utilise sheetContext pour le contenu
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe)
              _tile(sheetContext, Icons.delete_outline, 'Supprimer mon commentaire', color: Colors.redAccent)
            else
              _tile(sheetContext, Icons.report_gmailerrorred, 'Signaler ce contenu', color: Colors.orangeAccent),
            _tile(sheetContext, Icons.copy, 'Copier le texte'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Ajout du paramètre BuildContext context ici ⬇️
  Widget _tile(BuildContext context, IconData icon, String title, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontSize: 15)),
      onTap: () {
        Navigator.pop(context); // Maintenant 'context' est bien défini !
        // TODO: Implémenter l'action
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* ACTION ICON COMPONENT (Bouton d'ouverture)                                 */
/* -------------------------------------------------------------------------- */

class ActionIconCommentaire extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onOpenComments;

  const ActionIconCommentaire({
    super.key,
    required this.icon,
    this.label,
    required this.onOpenComments,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: onOpenComments,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.4),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}