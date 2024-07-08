import 'package:flutter/material.dart';
import 'package:seal_scanner/pages/login/index.dart';
import 'package:seal_scanner/pages/seal/index.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Seal Container Scanner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: LoginPage(),
        routes: {
          '/login': (context) => LoginPage(),
          '/seal': (context) => const SealPage(),
        });
  }
}
