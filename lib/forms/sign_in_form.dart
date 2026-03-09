// forms/sign_in_form.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../providers/user_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../config/api_config.dart';

// Utilisation des constantes définies dans AuthScreen ou config
const Color kSurfaceColor = Color(0xFF1E293B);
const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

class SignInForm extends ConsumerStatefulWidget {
  const SignInForm({super.key});

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Back",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "We missed you! Please sign in.",
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 35),

            // Champ Email
            _buildPremiumField(
              icon: Icons.alternate_email_rounded,
              hint: "Email or Phone",
              controller: _emailOrPhoneController,
            ),
            const SizedBox(height: 15),

            // Champ Password
            _buildPremiumField(
              icon: Icons.lock_outline_rounded,
              hint: "Password",
              controller: _passwordController,
              isPass: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),

            const SizedBox(height: 10),

            // Remember Me & Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: const Color(0xFFA855F7),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("Remember Me", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Color(0xFF22D3EE), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 35),

            // BOUTON SIGN IN (GRADIENT)
            GestureDetector(
              onTap: _isLoading ? null : loginUser,
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: kAccentGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          "SIGN IN",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Center(child: Text("Or sign in with", style: TextStyle(color: Colors.white38, fontSize: 13))),
            const SizedBox(height: 25),

            // GOOGLE LOGIN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: Colors.white,
                ),
                icon: const FaIcon(FontAwesomeIcons.google, size: 18, color: Colors.white),
                label: const Text("Google"),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool isPass = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPass,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 15),
          prefixIcon: Icon(icon, color: const Color(0xFF22D3EE), size: 22),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
        validator: (value) => (value == null || value.isEmpty) ? "Field required" : null,
      ),
    );
  }

  // --- LOGIQUE LOGIN (Identique à la tienne mais avec feedback UI) ---
  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailOrPhoneController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['error'] == null) {
        final user = User.fromJson(data['user']).copyWith(token: data['token']);
        await ref.read(userProvider.notifier).login(user);

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BottomNavBar()));
        }
      } else {
        if (mounted) _showSnackBar("❌ ${data['error'] ?? 'Identifiants invalides'}", Colors.redAccent);
      }
    } catch (e) {
      if (mounted) _showSnackBar("⚠️ Erreur de connexion au serveur", Colors.orangeAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }
}