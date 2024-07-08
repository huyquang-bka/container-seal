import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _controller = TextEditingController();
  String _laneId = '';

  @override
  void initState() {
    super.initState();
    _loadLaneId();
  }

  _loadLaneId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _laneId = prefs.getString('laneId') ?? '';
      _controller.text = _laneId;
    });
  }

  _saveLaneId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('laneId', _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lane ID Input'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: 200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Enter Lane ID',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _saveLaneId();
                  Navigator.pushNamed(context, '/seal');
                },
                child: const Text('Go'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
