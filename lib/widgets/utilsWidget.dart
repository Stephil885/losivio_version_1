import 'dart:ui';
import 'package:flutter/material.dart';

class DotsIndicator extends StatelessWidget {
  final int count;
  final int index;

  const DotsIndicator({required this.count, required this.index});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 14,
      child: Row(
        children: List.generate(count, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == index ? 14 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: i == index ? Colors.white : Colors.white.withOpacity(0.35),
            ),
          );
        }),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 10),
          Text("Chargement...", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}