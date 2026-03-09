// forms/sign_up_form.dart (VERSION MASTER - ULTRA PREMIUM)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../providers/user_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/user.dart';

const LinearGradient kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF22D3EE)],
);

class SignUpForm extends ConsumerStatefulWidget {
  const SignUpForm({super.key});

  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedLanguage;
  final List<Map<String, String>> _languages = [
    {"name": "Français", "flag": "🇫🇷", "code": "fr"},
    {"name": "Anglais", "flag": "🇬🇧", "code": "en"},
    {"name": "Espagnol", "flag": "🇪🇸", "code": "es"},
    {"name": "Arabe", "flag": "🇸🇦", "code": "ar"},
    {"name": "Mandarin", "flag": "🇨🇳", "code": "zh"},
  ];

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfUserLoggedIn());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkIfUserLoggedIn() async {
    final userAsync = ref.read(userProvider);
    userAsync.whenData((user) {
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavBar()),
        );
      }
    });
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a language")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "email": _emailController.text.trim(),
          "language": _selectedLanguage,
          "password": _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && data['user'] != null) {
        final user = User.fromJson(data['user']).copyWith(token: data['token']);
        await ref.read(userProvider.notifier).login(user);
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BottomNavBar()));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ ${data['message']}")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Server error")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
            const SizedBox(height: 8),
            const Text("Fill in your details to get started.", style: TextStyle(color: Colors.white38, fontSize: 15)),
            
            const SizedBox(height: 35),

            _buildField(Icons.person_outline, "Username", _usernameController),
            const SizedBox(height: 18),
            _buildField(Icons.email_outlined, "Email Address", _emailController, type: TextInputType.emailAddress),
            
            const SizedBox(height: 30),
            
            // --- SÉLECTEUR DE LANGUE MASTER DESIGN ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Language", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                if (_selectedLanguage != null)
                  Text(
                    _languages.firstWhere((l) => l['code'] == _selectedLanguage)['name']!, 
                    style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 13, fontWeight: FontWeight.bold)
                  ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 85, // Taille réduite pour plus de finesse
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _languages.length,
                separatorBuilder: (context, index) => const SizedBox(width: 15),
                // --- SÉLECTEUR DE LANGUE (LOGIQUE DE SÉLECTION CORRIGÉE) ---
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  // On compare maintenant avec le code (ex: 'fr') pour le border
                  final isSelected = _selectedLanguage == lang['code']; 

                  return GestureDetector(
                    onTap: () => setState(() => _selectedLanguage = lang['code']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 90,
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.12) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(24),
                        // Bordure dynamique : Intense si sélectionné, presque invisible sinon
                        border: Border.all(
                          color: isSelected ? const Color(0xFF22D3EE) : Colors.white.withOpacity(0.05),
                          width: isSelected ? 2.5 : 1,
                        ),
                        // Effet de lueur (Glow) pour confirmer le choix
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xFF22D3EE).withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: -2,
                          )
                        ] : [],
                      ),
                      child: Stack(
                        children: [
                          // Petit badge check en haut à droite
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Color(0xFF22D3EE), shape: BoxShape.circle),
                                child: const Icon(Icons.check, color: Colors.black, size: 10),
                              ),
                            ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(lang['flag']!, style: const TextStyle(fontSize: 26)),
                                const SizedBox(height: 4),
                                Text(
                                  lang['name']!,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white38,
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
            _buildField(
              Icons.lock_outline, "Password", _passwordController, 
              isPass: _obscurePassword,
              suffix: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),

            const SizedBox(height: 45),

            // BOUTON SIGN UP ACTION
            Hero(
              tag: 'auth_btn',
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: kAccentGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFEC4899).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("CREATE ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.2)),
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

  Widget _buildField(IconData icon, String hint, TextEditingController controller, {bool isPass = false, TextInputType type = TextInputType.text, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPass,
        keyboardType: type,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFA855F7), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
      ),
    );
  }
}