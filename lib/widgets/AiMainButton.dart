// widgets/AiMainbutton.dart

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'SingleVideo.dart';
import '../models/gift_item.dart';
import '../models/Streamer_model.dart';
import 'open.dart';
/*********************AiMainbutton******************/

enum RadialActionType { like, gift, shop, messages, invite, share, streamer,}
const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFEC4899), // pink-500
    Color(0xFFA855F7), // purple-500
    Color(0xFF22D3EE), // cyan-400
  ],
);

class AiMainButton extends StatelessWidget {
  final bool isOpen;
  final RadialActionType activeAction;
  final VoidCallback onToggle;
  final VoidCallback onExecute;

  const AiMainButton({
    super.key,
    required this.isOpen,
    required this.activeAction,
    required this.onExecute,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onToggle(); // 🔥 toggle TOUJOURS
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 60,
        height: 60,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: kAccentGradient,
          boxShadow: [
            if (!isOpen)
              BoxShadow(
                color: Colors.white.withOpacity(0.35),
                blurRadius: 28,
                spreadRadius: 4,
              )
            else
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 14,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) {
              return ScaleTransition(scale: anim, child: child);
            },
            child: AnimatedRotation(
              turns: isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Icon(
                isOpen ? Icons.close_rounded : Icons.auto_awesome,
                key: ValueKey(isOpen),
                color: Colors.black,
                size: 26,
              ),
            ),
          ),
        ),
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
        openStreamerPanel(context, widget.isLocked, (newValue) {
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
                        await openStreamerPanel(context, widget.isLocked, (val) => widget.onLockToggled(val));
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

class ActionData {
  final IconData icon;
  final String label;
  final RadialActionType type;
  const ActionData(this.icon, this.label, this.type);
}

class RadialAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const RadialAction({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow:
                  active
                      ? [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.9),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                      : [],
            ),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white70,
              fontSize: active ? 13 : 11,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}