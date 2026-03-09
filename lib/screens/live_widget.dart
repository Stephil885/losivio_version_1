import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

class LiveWidget extends StatefulWidget {
  const LiveWidget({super.key});

  @override
  State<LiveWidget> createState() => _LiveWidgetState();
}

class _LiveWidgetState extends State<LiveWidget>
    with SingleTickerProviderStateMixin {
  bool _menuOpen = false;

  void toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 🎥 LIVE FEED (mock)
        PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: 10,
          itemBuilder: (_, index) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Color(0xFF111827)],
                ),
              ),
              child: Center(
                child: Text(
                  'LIVE STREAM #$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),

        /// 🌑 OVERLAY
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// 🔘 RADIAL MENU
        Positioned(
          bottom: 100,
          right: 30,
          child: RadialMenu(
            isOpen: _menuOpen,
            onToggle: toggleMenu,
          ),
        ),
      ],
    );
  }
}

class RadialMenu extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const RadialMenu({
    super.key,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const double radius = 90;

    final actions = [
      _RadialAction(icon: Icons.favorite, label: 'Like'),
      _RadialAction(icon: Icons.card_giftcard, label: 'Gift'),
      _RadialAction(icon: Icons.shopping_bag, label: 'Shop'),
      _RadialAction(icon: Icons.share, label: 'Share'),
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        /// ACTIONS
        ...List.generate(actions.length, (i) {
          final angle = (2 * pi / actions.length) * i;
          final offset = Offset(
            radius * cos(angle),
            radius * sin(angle),
          );

          return AnimatedScale(
            scale: isOpen ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: isOpen ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Transform.translate(
                offset: isOpen ? offset : Offset.zero,
                child: actions[i],
              ),
            ),
          );
        }),

        /// MAIN BUTTON
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              isOpen ? Icons.close : Icons.flash_on,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}


class _RadialAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RadialAction({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ],
    );
  }
}
