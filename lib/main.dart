import 'package:flutter/material.dart';
import 'package:seal_scanner/pages/login/index.dart';
import 'package:seal_scanner/pages/seal/index.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String laneId = prefs.getString('laneId') ?? '';
  runApp(MyApp(laneId: laneId));
}

class MyApp extends StatelessWidget {
  final String laneId;
  const MyApp({Key? key, required this.laneId}) : super(key: key);

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
        home: laneId.isEmpty ? LoginPage() : const SealPage(),
        routes: {
          '/login': (context) => LoginPage(),
          '/seal': (context) => const SealPage(),
        });
  }
}
