// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import './providers/user_provider.dart';
import './widgets/bottom_nav_bar.dart';

class App extends ConsumerWidget { 
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Losivio',
      // userAsync.when gère automatiquement l'attente du chargement local
      home: userAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text("Erreur d'initialisation : $err")),
        ),
        data: (user) {
          return const BottomNavBar();
        },
      ),
    );
  }
}