import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/pantry_provider.dart';
import 'screens/home_screen.dart';
import 'services/pantry_repository.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PantryPalApp());
}

class PantryPalApp extends StatelessWidget {
  const PantryPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PantryProvider(PantryRepository())..load(),
      child: MaterialApp(
        title: 'Pantry Pal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    );
  }
}
