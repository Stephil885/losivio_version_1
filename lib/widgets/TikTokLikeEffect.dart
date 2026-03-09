import 'dart:math';
import 'package:flutter/material.dart';

class TikTokLikeEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onFinished;
  final double sizeMultiplier;
  final String emoji; // 👈 On ajoute le paramètre emoji ici

  const TikTokLikeEffect({
    super.key,
    required this.position,
    required this.onFinished,
    this.sizeMultiplier = 1.0,
    this.emoji = "❤️", // 👈 Valeur par défaut
  });

  @override
  State<TikTokLikeEffect> createState() => _TikTokLikeEffectState();
}

class _TikTokLikeEffectState extends State<TikTokLikeEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late double _randomRotation;
  late double _randomHorizontalOffset;

  @override
  void initState() {
    super.initState();
    
    _randomRotation = (Random().nextDouble() - 0.5) * 0.6;
    _randomHorizontalOffset = (Random().nextDouble() - 0.5) * 40;

    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000),
    );
    
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_controller);

    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.2 * widget.sizeMultiplier, 
          end: 1.3 * widget.sizeMultiplier
        ).chain(CurveTween(curve: Curves.easeOut)), 
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.3 * widget.sizeMultiplier, 
          end: 1.0 * widget.sizeMultiplier
        ).chain(CurveTween(curve: Curves.easeIn)), 
        weight: 65,
      ),
    ]).animate(_controller);

    _controller.forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 50,
      top: widget.position.dy - 50,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(
                _randomHorizontalOffset * _controller.value,
                -180 * _controller.value,
              ),
              child: Transform.scale(
                scale: _scale.value,
                child: Transform.rotate(
                  angle: _randomRotation,
                  child: Text(
                    widget.emoji, // 👈 REMPLACEMENT DES ICONES PAR L'EMOJI
                    style: TextStyle(
                      fontSize: 80, // Taille ajustée pour les emojis
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}