import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/block_store.dart';
import 'engine/engine.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final seed = jsonDecode(await rootBundle.loadString('assets/data/seed.json'));
  final catalog = Catalog.fromJson(Map<String, dynamic>.from(seed as Map));
  runApp(QuantitiesApp(catalog: catalog, store: BlockStore()));
}

class QuantitiesApp extends StatelessWidget {
  final Catalog catalog;
  final BlockStore store;
  const QuantitiesApp({super.key, required this.catalog, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حصر الكميات المعماري',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2C3E50),
      ),
      home: HomeScreen(catalog: catalog, store: store),
    );
  }
}
