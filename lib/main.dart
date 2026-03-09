// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/* void main() {
  runApp(const App());
} */
void main() {
  runApp(
    ProviderScope(
      child: const App(),
    ),
  );
}