// frontend/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../widgets/homes_page_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: HomeWidget(),
      ),
    );
  }
}

