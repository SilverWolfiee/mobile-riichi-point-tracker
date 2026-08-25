import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/main_menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riichi Tracker',
      theme: buildAppTheme(),
      home: const MainMenuScreen(),
    );
  }
}
