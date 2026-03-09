import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

import '../screens/home_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/create_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/broadcastLivePage.dart';

/* -------------------------------------------------------------------------- */
/*                              DESIGN TOKENS                                 */
/* -------------------------------------------------------------------------- */

const LinearGradient kDarkNavGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF0F172A), // slate-900
    Color(0xFF111827), // gray-900
    Color(0xFF1E293B), // slate-800
  ],
);

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFEC4899), // pink-500
    Color(0xFFA855F7), // purple-500
    Color(0xFF22D3EE), // cyan-400
  ],
);

/* -------------------------------------------------------------------------- */
/*                               BOTTOM NAV                                   */
/* -------------------------------------------------------------------------- */

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const DiscoverScreen(),
      const CreateScreen(),
      const MessagesScreen(),
      ProfileScreen(onChangeTab: _changeTabFromProfile),
    ];
  }

  void _changeTabFromProfile(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    const double navBarHeight = 68;
    const double centralButtonSize = 58;

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex == 2) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.black,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          child: _screens[_currentIndex],
        ),
        bottomNavigationBar: _currentIndex == 2
            ? null
            : SafeArea(
                top: false,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    /* ---------------------------- BAR + BLUR ---------------------------- */
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: navBarHeight,
                          decoration: BoxDecoration(
                            gradient: kDarkNavGradient,
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withOpacity(0.08),
                                width: 0.6,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _NavItem(icon: LineIcons.home, label: 'Accueil', index: 0, current: _currentIndex, onTap: _onTap),
                              _NavItem(icon: LineIcons.compass, label: 'Découvrir', index: 1, current: _currentIndex, onTap: _onTap),
                              const SizedBox(width: centralButtonSize),
                              _NavItem(icon: LineIcons.comments, label: 'Messages', index: 3, current: _currentIndex, onTap: _onTap),
                              _NavItem(icon: LineIcons.user, label: 'Profil', index: 4, current: _currentIndex, onTap: _onTap),
                            ],
                          ),
                        ),
                      ),
                    ),

                    /* ------------------------- CENTRAL ACTION ------------------------- */
                    Positioned(
                      bottom: navBarHeight / 2 - centralButtonSize / 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _currentIndex = 2),
                        child: Container(
                          width: centralButtonSize,
                          height: centralButtonSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: kAccentGradient,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22D3EE).withOpacity(0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(LineIcons.plus, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _onTap(int index) => setState(() => _currentIndex = index);
}

/* -------------------------------------------------------------------------- */
/*                               NAV ITEM                                     */
/* -------------------------------------------------------------------------- */

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == current;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive ? kAccentGradient : null,
                color: isActive ? null : Colors.transparent,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withOpacity(0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.55),
                size: isActive ? 24 : 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
