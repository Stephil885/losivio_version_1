/* // losivio/lib/widgets/live_widget.dart

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFEC4899), // pink-500
    Color(0xFFA855F7), // purple-500
    Color(0xFF22D3EE), // cyan-400
  ],
);

class LiveWidget extends StatefulWidget {
  const LiveWidget({super.key});

  @override
  State<LiveWidget> createState() => _LiveWidgetState();
}

class _LiveWidgetState extends State<LiveWidget> {
  bool _menuOpen = false;
  Offset _buttonPosition = const Offset(300, 500);

  void toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// LIVE FEED
        PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: 10,
          itemBuilder: (_, i) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Color(0xFF111827)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Text(
                'LIVE STREAM #$i',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        /// 🔥 OVERLAY DE FERMETURE (CLIQUABLE)
        /// 🔥 OVERLAY DE FERMETURE (CLIQUABLE)
        if (_menuOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: toggleMenu, // ferme hors menu uniquement
              child: Container(),
            ),
          ),

        /// MENU FLOTTANT
        Positioned(
          left: _buttonPosition.dx,
          top: _buttonPosition.dy,
          child: IgnorePointer(
            ignoring: false, // 👈 empêche l’overlay de capter ici
            child: GestureDetector(
              onPanUpdate: (d) {
                setState(() => _buttonPosition += d.delta);
              },
              child: RadialMenu(
                isOpen: _menuOpen,
                onToggle: toggleMenu,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               RADIAL MENU                                  */
/* -------------------------------------------------------------------------- */

class RadialMenu extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const RadialMenu({
    super.key,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu>
    with SingleTickerProviderStateMixin {
  static const double radius = 95;

  final actions = const [
    _ActionData(Icons.favorite, 'Like'),
    _ActionData(Icons.card_giftcard, 'Gift'),
    _ActionData(Icons.shopping_bag, 'Shop'),
    _ActionData(Icons.chat_bubble, 'Messages'),
    _ActionData(Icons.group_add, 'Inviter'),
    _ActionData(Icons.share, 'Share'),
  ];

  late AnimationController _snapController;
  double _rotation = 0;
  double _startAngle = 0;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  double _angleFromCenter(Offset p) {
    const c = Offset(28, 28);
    return atan2(p.dy - c.dy, p.dx - c.dx);
  }

  void _snapToNearest() {
    final step = 2 * pi / actions.length;
    final snapped = (_rotation / step).round() * step;

    final index =
        ((-snapped / step) % actions.length).round() % actions.length;

    _snapController.reset();

    late Animation<double> animation;

    animation = Tween<double>(
      begin: _rotation,
      end: snapped,
    ).animate(
      CurvedAnimation(
        parent: _snapController,
        curve: Curves.easeOutCubic,
      ),
    )
      ..addListener(() {
        setState(() {
          _rotation = animation.value;
        });
      });

    _snapController.forward();

    if (_activeIndex != index) {
      _activeIndex = index;
      HapticFeedback.selectionClick();
    }
  }

  void _openPanel(BuildContext context) async {
    final label = actions[_activeIndex].label;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: 320,
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.isOpen
          ? (d) => _startAngle = _angleFromCenter(d.localPosition)
          : null,
      onPanUpdate: widget.isOpen
          ? (d) {
              final angle = _angleFromCenter(d.localPosition);
              setState(() => _rotation += angle - _startAngle);
              _startAngle = angle;
            }
          : null,
      onPanEnd: widget.isOpen ? (_) => _snapToNearest() : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// ACTIONS
          Transform.rotate(
            angle: _rotation,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(actions.length, (i) {
                final angle = 2 * pi * i / actions.length;
                final offset =
                    Offset(radius * cos(angle), radius * sin(angle));

                final isActive = i == _activeIndex;

                return AnimatedScale(
                  scale: widget.isOpen
                      ? (isActive ? 1.25 : 1)
                      : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Transform.translate(
                    offset: widget.isOpen ? offset : Offset.zero,
                    child: _RadialAction(
                      icon: actions[i].icon,
                      label: actions[i].label,
                      active: isActive,
                      onTap: () {
                        setState(() => _activeIndex = i);
                        _openPanel(context); // ouvre le panel
                      },
                    ),

                  ),
                );
              }),
            ),
          ),

          /// MAIN BUTTON
          /// MAIN AI BUTTON
          AiMainButton(
            isOpen: widget.isOpen,
            onTap: widget.onToggle,
            
          ),

        ],
      ),
    );
  }
}
/* -------------------------------------------------------------------------- */
/*                              ACTION DATA                                   */
/* -------------------------------------------------------------------------- */

class _ActionData {
  final IconData icon;
  final String label;
  const _ActionData(this.icon, this.label);
}

/* -------------------------------------------------------------------------- */
/*                              RADIAL ACTION                                 */
/* -------------------------------------------------------------------------- */

class _RadialAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RadialAction({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap, // 🔥 IMPORTANT
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.9),
                        blurRadius: 18,
                        spreadRadius: 2,
                      )
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

/*********************AiMainbutton******************/

class AiMainButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const AiMainButton({
    super.key,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 60,
        height: 60,
        padding: const EdgeInsets.all(2.5), // épaisseur bordure gradient
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: kAccentGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) {
              return ScaleTransition(scale: anim, child: child);
            },
            child: Icon(
              isOpen ? Icons.close_rounded : Icons.auto_awesome,
              key: ValueKey(isOpen),
              color: Colors.black,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
} */