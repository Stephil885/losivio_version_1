// widgets/liveSpectateur.dart

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart'; 
import 'AiMainbutton.dart';
import '../models/gift_item.dart';
import '../models/Streamer_model.dart';
import 'TikTokLikeEffect.dart';
import 'open.dart';
import 'RadialMenu.dart';
import 'GiftCategory.dart'; 
import '../utils/streamers_layout.dart';

class LiveStreamerPage extends StatefulWidget {
  final List<StreamerModel> streamers;
  final RtcEngine engine;
  final String channelName;
  const LiveStreamerPage({
    super.key,
    required this.streamers,
    required this.engine,
    required this.channelName,
  });

  @override
  State<LiveStreamerPage> createState() => _LiveStreamerPageState();
}

class _LiveStreamerPageState extends State<LiveStreamerPage> with TickerProviderStateMixin {
  bool _menuOpen = false;
  bool _isScreenLocked = true;
  Offset? _buttonPosition;
  GiftItem? _lastGift;
  int _tokenBalance = 100;
  int _displayedBalance = 100;
  Timer? _giftRandomTimer;

  void toggleMenu() => setState(() => _menuOpen = !_menuOpen);

  void _animateBalance(int from, int to) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final animation = IntTween(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    animation.addListener(() {
      setState(() => _displayedBalance = animation.value);
    });

    controller.forward().whenComplete(controller.dispose);
  }

  void _onGiftSelected(GiftItem gift) {
    print("🔔 BOUTON CLIQUÉ : Tentative d'envoi du cadeau : ${gift.name}");

    if (_tokenBalance < gift.cost) {
      print("❌ ÉCHEC : Pas assez de tokens (Solde: $_tokenBalance, Coût: ${gift.cost})");
      return;
    }

    final oldBalance = _tokenBalance;
    final newBalance = _tokenBalance - gift.cost;
    
    setState(() {
      _tokenBalance = newBalance;
      _lastGift = gift;
      print("💾 ÉTAT MIS À JOUR : _lastGift est maintenant configuré sur ${gift.emoji}");
    });

    _animateBalance(oldBalance, newBalance);

    if (gift.isPremium) {
      print("✨ EFFET PREMIUM : Lancement du dialogue pour ${gift.name}");
    }
  }

  // NOTE: J'ai supprimé _buildVideo et _buildGrid ici comme demandé.
  // La logique est maintenant déléguée à LiveVideoGrid et SingleVideo.

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final streamers = widget.streamers;
    if (streamers.isEmpty) return const SizedBox();

    _buttonPosition ??= Offset(size.width - 210, size.height * 0.7 - 110);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            
            itemBuilder: (_, index) {
            
              return LiveVideoGrid(
                streamers: widget.streamers,
                roomId: index,
                isLocked: _isScreenLocked,
                engine: widget.engine, // 🔥 Ajout Agora
                channelName: widget.channelName, // 🔥 Ajout Agora
                onRandomGift: (gift) => _onGiftSelected(gift),
              );
            },
          ),

          // 2. L'ANIMATION DU CADEAU
          if (_lastGift != null)
            TweenAnimationBuilder<double>(
              key: ValueKey(_lastGift!.hashCode + DateTime.now().millisecondsSinceEpoch),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              onEnd: () => setState(() => _lastGift = null),
              builder: (context, value, child) {
                final screenHeight = MediaQuery.of(context).size.height;
                final startPos = -200.0;
                final endPos = screenHeight / 2 - 10; 
                final currentBottom = startPos + (endPos - startPos) * Curves.easeOutBack.transform(value);

                return Positioned(
                  bottom: currentBottom,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: value < 0.1 ? value * 10 : (value > 0.8 ? (1 - value) * 5 : 1.0),
                      child: Transform.scale(
                        scale: 0.6 + (0.4 * value),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _lastGift!.isPremium 
                              ? Colors.amberAccent.withOpacity(0.7) 
                              : Colors.purpleAccent.withOpacity(0.5),
                          blurRadius: _lastGift!.isPremium ? 80 : 50,
                          spreadRadius: _lastGift!.isPremium ? 30 : 20,
                        )
                      ],
                    ),
                    child: Text(
                      _lastGift!.emoji, 
                      style: TextStyle(fontSize: _lastGift!.isPremium ? 150 : 100),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Card(
                    color: _lastGift!.isPremium ? Colors.amber : Colors.black87,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text(
                        _lastGift!.isPremium ? "CADEAU EXCLUSIF" : "OFFRE ${_lastGift!.name.toUpperCase()}",
                        style: TextStyle(
                          color: _lastGift!.isPremium ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_menuOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: toggleMenu,
                child: Container(color: Colors.transparent),
              ),
            ),

          Positioned(
            left: _buttonPosition!.dx,
            top: _buttonPosition!.dy,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: (details) {
                if (_menuOpen) return;
                setState(() {
                  _buttonPosition = _buttonPosition! + details.delta;
                });
              },
              child: SizedBox(
                width: 220,
                height: 220,
                child: RadialMenu(
                  isOpen: _menuOpen,
                  onToggle: toggleMenu,
                  onGiftSelected: _onGiftSelected,
                  tokenBalance: _tokenBalance,
                  isLocked: _isScreenLocked,
                  onLockToggled: (val) {
                    setState(() => _isScreenLocked = val);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// LIVE VIDEO GRID (Gère l'agencement et passe l'engine aux SingleVideo)
// ------------------------------------------------------------------------

class LiveVideoGrid extends StatefulWidget {
  final List<StreamerModel> streamers;
  final int roomId;
  final bool isLocked;
  final Function(GiftItem)? onRandomGift;
  final RtcEngine engine; // 🔥 Requis pour Agora
  final String channelName; // 🔥 Requis pour Agora

  const LiveVideoGrid({
    super.key,
    required this.streamers,
    required this.roomId,
    required this.engine,
    required this.channelName,
    this.isLocked = false,
    this.onRandomGift,
  });

  @override
  State<LiveVideoGrid> createState() => _LiveVideoGridState();
}

class _LiveVideoGridState extends State<LiveVideoGrid> {
  late List<StreamerModel> _orderedStreamers;
  String? _fullscreenStreamerId;
  final List<Map<String, dynamic>> _hearts = [];

  Timer? _infiniteLikeTimer;
  Offset? _currentTouchPosition;
  int _ticksCount = 0;
  Timer? _giftTimer; 

  @override
  void initState() {
    super.initState();
    // Assure-toi que _normalize est bien importé ou défini dans streamers_layout.dart
    _orderedStreamers = _normalize(widget.streamers); 
  }

  @override
  void dispose() {
    _stopInfiniteLikes();
    super.dispose();
  }

  @override
  void didUpdateWidget(LiveVideoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamers != widget.streamers) {
      setState(() {
        _orderedStreamers = _normalize(widget.streamers);
        _fullscreenStreamerId = null;
      });
    }
    if (oldWidget.isLocked && !widget.isLocked) {
      _stopInfiniteLikes();
    }
  }

  // ... [LOGIQUE LIKE ET CADEAUX IDENTIQUE À TON CODE ORIGINAL] ...
  void _startInfiniteLikes(Offset startPosition) {
    if (!widget.isLocked) return;
    _currentTouchPosition = startPosition;
    _ticksCount = 0;
    _addElement(_currentTouchPosition!);
    _infiniteLikeTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (mounted && _currentTouchPosition != null) {
        _addElement(_currentTouchPosition!);
      }
    });
    _scheduleNextRandomGift();
  }

  void _scheduleNextRandomGift() {
    _giftTimer?.cancel();
    if (!mounted || _currentTouchPosition == null) return;
    final randomDelay = Random().nextInt(4000) + 1000; 
    _giftTimer = Timer(Duration(milliseconds: randomDelay), () {
      _sendSystemGift();
      _scheduleNextRandomGift(); 
    });
  }

  void _sendSystemGift() {
    if (widget.onRandomGift == null) return;
    final rand = Random();
    final category = categories[rand.nextInt(categories.length)];
    final gift = category.gifts[rand.nextInt(category.gifts.length)];
    widget.onRandomGift!(gift.copyWith(cost: 0));
  }

  void _updateTouchPosition(Offset newPosition) {
    _currentTouchPosition = newPosition;
  }

  void _stopInfiniteLikes() {
    _infiniteLikeTimer?.cancel();
    _giftTimer?.cancel(); 
    _infiniteLikeTimer = null;
    _giftTimer = null;
    _currentTouchPosition = null;
  }

  void _addElement(Offset position, {bool forceHeart = false}) {
    final random = Random();
    final randomOffset = Offset(
      (random.nextDouble() * 30) - 15, 
      (random.nextDouble() * 30) - 15
    );
    final id = DateTime.now().millisecondsSinceEpoch.toString() + random.nextInt(1000).toString();
    String content = "❤️"; 

    setState(() {
      _hearts.add({
        'id': id, 
        'position': position + randomOffset,
        'size': 1.0, 
        'emoji': content,
      });
    });
    HapticFeedback.lightImpact(); 
  }

  List<StreamerModel> _normalize(List<StreamerModel> list) {
    if (list.isEmpty) return [];
    final hasOwner = list.any((s) => s.role == StreamerRole.owner);
    if (!hasOwner) {
      return [list.first.copyWith(role: StreamerRole.owner), ...list.skip(1)];
    }
    return List.from(list);
  }

  void _handleSwap(int clickedIndex) {
    if (widget.isLocked || clickedIndex == 0 || _orderedStreamers.length < 2) return;
    setState(() {
      final StreamerModel clickedStreamer = _orderedStreamers[clickedIndex];
      final StreamerModel currentHost = _orderedStreamers[0];
      _orderedStreamers[0] = clickedStreamer;
      _orderedStreamers[clickedIndex] = currentHost;
    });
    HapticFeedback.mediumImpact();
  }

  void _toggleFullscreen(String streamerId) {
    if (widget.isLocked) {
      HapticFeedback.vibrate();
      return;
    }
    setState(() {
      _fullscreenStreamerId = (_fullscreenStreamerId == streamerId) ? null : streamerId;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (_orderedStreamers.isEmpty) return Container(color: Colors.black);

    Widget mainContent;

    // Helper pour créer une SingleVideo avec les params Agora
    Widget createSingleVideo(StreamerModel s, {bool isFullscreen = false}) {
        return SingleVideo(
            streamer: s,
            engine: widget.engine,
            channelName: widget.channelName,
            isFullscreen: isFullscreen,
            key: ValueKey(s.uid),
        );
    }

    if (_fullscreenStreamerId != null) {
      final target = _orderedStreamers.firstWhere(
        (s) => s.uid.toString() == _fullscreenStreamerId,
        orElse: () => _orderedStreamers[0],
      );
      mainContent = GestureDetector(
        onDoubleTap: () => _toggleFullscreen(target.uid.toString()),
        child: createSingleVideo(target, isFullscreen: true),
      );
    } else {
      final host = _orderedStreamers[0];
      final guests = _orderedStreamers.skip(1).toList();
      final totalCount = _orderedStreamers.length;

      Widget videoItemWrapper(StreamerModel streamer, int index) {
        return GestureDetector(
          onTap: () => _handleSwap(index),
          onDoubleTap: () => _toggleFullscreen(streamer.uid.toString()),
          child: createSingleVideo(streamer),
        );
      }

      if (totalCount == 1) {
        mainContent = videoItemWrapper(host, 0);
      } else if (totalCount == 2) {
        mainContent = Column(
          children: [
            Expanded(child: videoItemWrapper(host, 0)),
            const Divider(height: 2, color: Colors.black),
            Expanded(child: videoItemWrapper(guests[0], 1)),
          ],
        );
      } else if (totalCount == 3) {
        mainContent = Column(
          children: [
            Expanded(flex: 3, child: videoItemWrapper(host, 0)),
            const Divider(height: 2, color: Colors.black),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: videoItemWrapper(guests[0], 1)),
                  const VerticalDivider(width: 2, color: Colors.black),
                  Expanded(child: videoItemWrapper(guests[1], 2)),
                ],
              ),
            ),
          ],
        );
      } else {
        mainContent = Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: videoItemWrapper(host, 0)),
                  const VerticalDivider(width: 2, color: Colors.black),
                  Expanded(child: videoItemWrapper(guests[0], 1)),
                ],
              ),
            ),
            const Divider(height: 2, color: Colors.black),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: videoItemWrapper(guests[1], 2)),
                  const VerticalDivider(width: 2, color: Colors.black),
                  Expanded(child: videoItemWrapper(guests.length > 2 ? guests[2] : guests[1], 3)),
                ],
              ),
            ),
          ],
        );
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTapDown: (details) {
        if (widget.isLocked) {
          _addElement(details.localPosition, forceHeart: true);
        }
      },
      onLongPressStart: (details) => _startInfiniteLikes(details.localPosition),
      onLongPressMoveUpdate: (details) => _updateTouchPosition(details.localPosition),
      onLongPressEnd: (_) => _stopInfiniteLikes(),
      onLongPressCancel: () => _stopInfiniteLikes(),

      child: Stack(
        children: [
          Container(color: Colors.black, child: mainContent),
          
          ..._hearts.map((item) => TikTokLikeEffect(
                key: ValueKey(item['id']),
                position: item['position'],
                sizeMultiplier: item['size'] ?? 0,
                emoji: item['emoji'] ?? "❤️",
                onFinished: () {
                  if (mounted) {
                    setState(() => _hearts.removeWhere((h) => h['id'] == item['id']));
                  }
                },
              )),
          
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isLocked ? Colors.redAccent : Colors.transparent, 
                  width: 1
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "LIVE #${widget.roomId} • 👥 ${_orderedStreamers.length}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  if (widget.isLocked) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.lock, color: Colors.redAccent, size: 14),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// SINGLE VIDEO : INTÉGRATION AGORA
// ------------------------------------------------------------------------

class SingleVideo extends StatelessWidget {
  final StreamerModel streamer;
  final bool isFullscreen;
  final RtcEngine engine;
  final String channelName;

  const SingleVideo({
    super.key, 
    required this.streamer, 
    required this.engine,
    required this.channelName,
    this.isFullscreen = false
  });

  @override
  Widget build(BuildContext context) {
    final isHost = streamer.role == StreamerRole.owner;
    final isVip = streamer.role == StreamerRole.vip;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 🔥 LOGIQUE AGORA ICI
        // Si c'est l'utilisateur local
        if (streamer.isLocal)
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: engine,
              canvas: const VideoCanvas(uid: 0), // 0 indique l'utilisateur local
            ),
          )
        // Si c'est un utilisateur distant
        else
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: engine,
              connection: RtcConnection(channelId: channelName),
              canvas: VideoCanvas(uid: streamer.uid),
            ),
          ),

        // --- OVERLAYS UI (Gradients, Badges, etc.) ---
        
        if (isFullscreen)
          const Positioned(
            top: 60,
            right: 20,
            child: Icon(Icons.fullscreen_exit, color: Colors.white54, size: 28),
          ),

        // Overlay dégradé pour le nom
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 10,
          left: 10,
          child: Row(
            children: [
              if (isHost)
                RoleBadge(label: "HOST", color: Colors.redAccent)
              else if (isVip)
                RoleBadge(label: "VIP", color: Colors.amber),
              Text(
                "ID: ${streamer.uid}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          bottom: 10,
          right: 10,
          child: Icon(Icons.mic, color: Colors.white70, size: 20),
        ),
      ],
    );
  }
}