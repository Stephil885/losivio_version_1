// screens/auth_screen.dart

import 'package:flutter/material.dart';
import '../forms/sign_in_form.dart';
import '../forms/sign_up_form.dart';

// --- CONFIGURATION DESIGN REPRISE ---
const Color kBackgroundColor = Color(0xFF0F172A);
const Color kSurfaceColor = Color(0xFF1E293B);

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header Premium avec Logo ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => kAccentGradient.createShader(bounds),
                    child: const Text(
                      "Losivio",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Text(
                    "Connect with the world",
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  
                  // TabBar stylisée
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: kAccentGradient,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: "Sign Up"),
                        Tab(text: "Sign In"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- Formulaires ----
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: kBackgroundColor, // On garde le fond sombre
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    SignUpForm(),
                    SignInForm(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}