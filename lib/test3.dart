// widget/live_widget.dart
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart'; 

import 'AiMainbutton.dart';
import 'LiveChatSheet.dart';
import 'LiveShopSheet.dart';
import 'LiveGiftSheet.dart';
import '../models/gift_item.dart';
import 'models/Streamer_model.dart';
import '../components/listStreamers.dart';
import 'TikTokLikeEffect.dart';
import 'open.dart';
import 'SingleVideo.dart';
import 'GiftCategory.dart'; // 👈 Importation de ton fichier de catégories

class LiveWidget extends StatefulWidget {
  const LiveWidget({super.key});

  @override
  State<LiveWidget> createState() => _LiveWidgetState();
}

class _LiveWidgetState extends State<LiveWidget> with TickerProviderStateMixin {
  bool _menuOpen = false;
  bool _isScreenLocked = true;
  Offset? _buttonPosition;
  GiftItem? _lastGift;
  int _tokenBalance = 100;
  int _displayedBalance = 100;

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
    if (_tokenBalance < gift.cost) return;

    final oldBalance = _tokenBalance;
    final newBalance = _tokenBalance - gift.cost;

    setState(() {
      _tokenBalance = newBalance;
      _lastGift = gift;
    });

    _animateBalance(oldBalance, newBalance);

    if (gift.isPremium) {
      _showPremiumEffect(gift);
    }
  }

  void _showPremiumEffect(GiftItem gift) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) {
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            builder: (_, scale, __) {
              return Transform.scale(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(gift.emoji, style: const TextStyle(fontSize: 140)),
                    const SizedBox(height: 16),
                    Text(
                      gift.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "CADEAU PREMIUM 🎆",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    _buttonPosition ??= Offset(size.width - 210, size.height * 0.7 - 110);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: liveStreams.length,
            itemBuilder: (_, index) {
              final List<StreamerMock> streamers = liveStreams[index];
              return LiveVideoGrid(
                streamers: streamers,
                roomId: index,
                isLocked: _isScreenLocked,
              );
            },
          ),

          if (_lastGift != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 0),
                duration: const Duration(seconds: 2),
                onEnd: () => setState(() => _lastGift = null),
                builder: (_, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -40 * value),
                    child: Opacity(opacity: 1 - value, child: child),
                  );
                },
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      "${_lastGift!.emoji} ${_lastGift!.name}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
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

class LiveVideoGrid extends StatefulWidget {
  final List<StreamerMock> streamers;
  final int roomId;
  final bool isLocked;

  const LiveVideoGrid({
    super.key,
    required this.streamers,
    required this.roomId,
    this.isLocked = false,
  });

  @override
  State<LiveVideoGrid> createState() => _LiveVideoGridState();
}

class _LiveVideoGridState extends State<LiveVideoGrid> {
  late List<StreamerMock> _orderedStreamers;
  String? _fullscreenStreamerId;
  final List<Map<String, dynamic>> _hearts = [];

  Timer? _infiniteLikeTimer;
  Offset? _currentTouchPosition;
  int _ticksCount = 0;
  double _currentSizeMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
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

  // ------------------------------------------------------------------------
  // LOGIQUE DU LIKE INFINI + CADEAUX ALÉATOIRES
  // ------------------------------------------------------------------------

  void _startInfiniteLikes(Offset startPosition) {
    if (!widget.isLocked) return;
    
    _currentTouchPosition = startPosition;
    _ticksCount = 0;
    _currentSizeMultiplier = 1.0;

    _addElement(_currentTouchPosition!);

    _infiniteLikeTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (mounted && _currentTouchPosition != null) {
        _ticksCount++;
        _currentSizeMultiplier = min(1.0 + (_ticksCount * 0.05), 2.5);
        _addElement(_currentTouchPosition!);
      }
    });
  }

  void _updateTouchPosition(Offset newPosition) {
    _currentTouchPosition = newPosition;
  }

  void _stopInfiniteLikes() {
    _infiniteLikeTimer?.cancel();
    _infiniteLikeTimer = null;
    _currentTouchPosition = null;
    _ticksCount = 0;
    _currentSizeMultiplier = 1.0;
  }

  /// Ajoute un cœur ou un cadeau aléatoire issu de GiftCategory.dart
  void _addElement(Offset position) {
    final random = Random();
    final randomOffset = Offset(
      (random.nextDouble() * 30) - 15, 
      (random.nextDouble() * 30) - 15
    );

    final id = DateTime.now().millisecondsSinceEpoch.toString() + random.nextInt(1000).toString();
    
    // Déterminer le contenu (Cœur ou Cadeau aléatoire)
    String content = "❤️";
    // 30% de chance d'afficher un cadeau aléatoire quand on mitraille l'écran
    if (random.nextDouble() < 0.3 && categories.isNotEmpty) {
      // 1. Choisir une catégorie au hasard
      final category = categories[random.nextInt(categories.length)];
      if (category.gifts.isNotEmpty) {
        // 2. Choisir un cadeau au hasard dans cette catégorie
        content = category.gifts[random.nextInt(category.gifts.length)].emoji;
      }
    }

    setState(() {
      _hearts.add({
        'id': id, 
        'position': position + randomOffset,
        'size': _currentSizeMultiplier,
        'emoji': content, // On stocke l'emoji choisi
      });
    });

    if (_ticksCount < 10) {
      HapticFeedback.lightImpact();
    } else if (_ticksCount < 25) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  // ------------------------------------------------------------------------
  // LOGIQUE DE GRILLE ET SWAP
  // ------------------------------------------------------------------------

  List<StreamerMock> _normalize(List<StreamerMock> list) {
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
      final StreamerMock clickedStreamer = _orderedStreamers[clickedIndex];
      final StreamerMock currentHost = _orderedStreamers[0];
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

    if (_fullscreenStreamerId != null) {
      final target = _orderedStreamers.firstWhere(
        (s) => s.id.toString() == _fullscreenStreamerId,
        orElse: () => _orderedStreamers[0],
      );
      mainContent = GestureDetector(
        onDoubleTap: () => _toggleFullscreen(target.id.toString()),
        child: SingleVideo(streamer: target, isFullscreen: true),
      );
    } else {
      final host = _orderedStreamers[0];
      final guests = _orderedStreamers.skip(1).toList();
      final totalCount = _orderedStreamers.length;

      Widget videoItem(StreamerMock streamer, int index) {
        return GestureDetector(
          onTap: () => _handleSwap(index),
          onDoubleTap: () => _toggleFullscreen(streamer.id.toString()),
          child: SingleVideo(streamer: streamer, key: ValueKey(streamer.id)),
        );
      }

      if (totalCount == 1) {
        mainContent = videoItem(host, 0);
      } else if (totalCount == 2) {
        mainContent = Column(
          children: [
            Expanded(child: videoItem(host, 0)),
            const Divider(height: 2, color: Colors.black),
            Expanded(child: videoItem(guests[0], 1)),
          ],
        );
      } else if (totalCount == 3) {
        mainContent = Column(
          children: [
            Expanded(flex: 3, child: videoItem(host, 0)),
            const Divider(height: 2, color: Colors.black),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: videoItem(guests[0], 1)),
                  const VerticalDivider(width: 2, color: Colors.black),
                  Expanded(child: videoItem(guests[1], 2)),
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
                  Expanded(child: videoItem(host, 0)),
                  const VerticalDivider(width: 2, color: Colors.black),
                  Expanded(child: videoItem(guests[0], 1)),
                ],
              ),
            ),
            const Divider(height: 2, color: Colors.black),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: videoItem(guests[1], 2)),
                  const VerticalDivider(width: 2, color: Colors.black),
                  Expanded(child: videoItem(guests.length > 2 ? guests[2] : guests[1], 3)),
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
          _addElement(details.localPosition);
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
                sizeMultiplier: item['size'] ?? 0, // On garde ta croissance
                emoji: item['emoji'] ?? "❤️",      // 👈 ON PASSE L'EMOJI ICI
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

/* -------------------------------------------------------------------------- */
/* RADIAL MENU (Rotation et Actions)                                          */
/* -------------------------------------------------------------------------- */

class RadialMenu extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final Function(GiftItem)? onGiftSelected;
  final int tokenBalance;
  final bool isLocked;
  final Function(bool) onLockToggled;

  const RadialMenu({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.tokenBalance,
    required this.isLocked,
    required this.onLockToggled,
    this.onGiftSelected,
  });

  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu> with SingleTickerProviderStateMixin {
  static const double radius = 95;
  double _accumulatedRotation = 0;

  final actions = [
    ActionData(Icons.favorite, 'Like', RadialActionType.like),
    ActionData(Icons.card_giftcard, 'Gift', RadialActionType.gift),
    ActionData(Icons.shopping_bag, 'Shop', RadialActionType.shop),
    ActionData(Icons.chat_bubble, 'Messages', RadialActionType.messages),
    ActionData(Icons.group_add, 'Inviter', RadialActionType.invite),
    ActionData(Icons.share, 'Share', RadialActionType.share),
    ActionData(Icons.videocam, 'Streamer', RadialActionType.streamer),
  ];

  RadialActionType get activeAction => actions[_activeIndex].type;

  late AnimationController _snapController;
  double _rotation = 0;
  double _startAngle = 0;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _executeActiveAction(BuildContext context) {
    switch (activeAction) {
      case RadialActionType.messages:
        openChat(context);
        break;
      case RadialActionType.shop:
        openShop(context);
        break;
      case RadialActionType.streamer:
        _openStreamerPanel(context, widget.isLocked, (newValue) {
          widget.onLockToggled(newValue);
        });
        break;
      case RadialActionType.like:
        HapticFeedback.mediumImpact();
        break;
      case RadialActionType.gift:
        if (widget.onGiftSelected != null) {
          openGift(context, widget.onGiftSelected!, widget.tokenBalance);
        }
        break;
      default:
        break;
    }
  }

  double _angleFromCenter(Offset p) {
    const center = Offset(110, 110);
    return atan2(p.dy - center.dy, p.dx - center.dx);
  }

  double _normalizeAngle(double angle) {
    while (angle > pi) angle -= 2 * pi;
    while (angle < -pi) angle += 2 * pi;
    return angle;
  }

  void _snapToNearest() {
    final step = 2 * pi / actions.length;
    final snapped = (_rotation / step).round() * step;
    final index = ((-snapped / step) % actions.length).round() % actions.length;

    _snapController.reset();
    late Animation<double> animation;
    animation = Tween<double>(begin: _rotation, end: snapped).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    animation.addListener(() => setState(() => _rotation = animation.value));
    _snapController.forward();

    if (_activeIndex != index) {
      _activeIndex = index;
      HapticFeedback.selectionClick();
    }
    _accumulatedRotation = _rotation;
  }

  void _activateIndex(int index) {
    final step = 2 * pi / actions.length;
    final targetRotation = -index * step;
    _snapController.reset();
    late Animation<double> animation;
    animation = Tween<double>(begin: _rotation, end: targetRotation).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    animation.addListener(() => setState(() => _rotation = animation.value));
    _activeIndex = index;
    HapticFeedback.selectionClick();
    _snapController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.isOpen ? (event) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(event.position);
        _startAngle = _angleFromCenter(local);
      } : null,
      onPointerMove: widget.isOpen ? (event) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(event.position);
        final angle = _angleFromCenter(local);
        double delta = angle - _startAngle;
        delta = _normalizeAngle(delta);
        if (delta.abs() < 0.002) return;
        _startAngle = angle;
        _accumulatedRotation += delta;
        setState(() => _rotation = _accumulatedRotation);
      } : null,
      onPointerUp: widget.isOpen ? (_) => _snapToNearest() : null,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: List.generate(actions.length, (i) {
              final angle = (2 * pi * i / actions.length) + _rotation;
              final offset = Offset(radius * cos(angle), radius * sin(angle));
              final isActive = i == _activeIndex;
              const double actionSize = 48;

              return Positioned(
                left: (220 / 2) + offset.dx - (actionSize / 2),
                top: (220 / 2) + offset.dy - (actionSize / 2) - 9,
                child: AnimatedScale(
                  scale: widget.isOpen ? (isActive ? 1.25 : 1) : 0,
                  duration: const Duration(milliseconds: 250),
                  child: RadialAction(
                    icon: actions[i].icon,
                    label: actions[i].label,
                    active: isActive,
                    onTap: () async {
                      _activateIndex(i);
                      widget.onToggle();
                      if (actions[i].type == RadialActionType.messages) await openChat(context);
                      if (actions[i].type == RadialActionType.shop) await openShop(context);
                      if (actions[i].type == RadialActionType.gift) {
                        await openGift(context, widget.onGiftSelected!, widget.tokenBalance);
                      }
                      if (actions[i].type == RadialActionType.streamer) {
                        await _openStreamerPanel(context, widget.isLocked, (val) => widget.onLockToggled(val));
                      }
                    },
                  ),
                ),
              );
            }),
          ),
          AiMainButton(
            isOpen: widget.isOpen,
            activeAction: activeAction,
            onToggle: widget.onToggle,
            onExecute: () => _executeActiveAction(context),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* HELPERS PANNEAU STREAMER                                                   */
/* -------------------------------------------------------------------------- */

Future<void> _openStreamerPanel(BuildContext context, bool currentLock, Function(bool) onLockChanged) async {
  bool isTranslated = true;
  await showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            height: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 25),
                const Text("PARAMÈTRES DU LIVE 🎥", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                buildToggleRow(
                  icon: Icons.lock_outline,
                  label: "Verrouiller l'écran",
                  value: currentLock,
                  onChanged: (val) {
                    setModalState(() => currentLock = val!);
                    onLockChanged(val!);
                    HapticFeedback.lightImpact();
                  },
                ),
                const Divider(color: Colors.white10, height: 32),
                buildToggleRow(
                  icon: Icons.translate,
                  label: "Traduire le live",
                  value: isTranslated,
                  onChanged: (val) {
                    setModalState(() => isTranslated = val!);
                    HapticFeedback.lightImpact();
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("VALIDER", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}