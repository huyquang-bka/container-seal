import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:seal_scanner/helpers/builder.dart';
import 'package:seal_scanner/utils/mqtt.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the MQTT client
import 'package:image/image.dart' as img;

class SealPage extends StatefulWidget {
  const SealPage({super.key});

  @override
  State<SealPage> createState() => _SealPageState();
}

class _SealPageState extends State<SealPage> {
  File _image = File('');
  String _textRecognized = '';
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final TextEditingController _textController = TextEditingController();
  late MQTTClient _mqttClient;
  String laneId = "";
  final int _maxHeight = 500;
  Color? _borderColor;

  // MQTT
  String broker = 'broker.hivemq.com';
  int port = 1883;
  String username = '';
  String password = "";
  String topic = "";
  // generate random client id from current time
  String clientId = "mobile-${DateTime.now().millisecondsSinceEpoch}";

  @override
  void initState() {
    super.initState();
    _loadTopic();
  }

  @override
  void dispose() {
    _mqttClient.disconnect();
    super.dispose();
  }

  void _loadTopic() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    laneId = prefs.getString('laneId') ?? "";
    // Assume the topic is the same as the clientId
    setState(() {
      topic = "container/$laneId";
    });
    _connectMQTT();
  }

  void _connectMQTT() async {
    print("Topic: $topic");
    _mqttClient = MQTTClient(
      broker: broker,
      port: port,
      clientId: clientId,
      username: username,
      password: password,
      topic: topic,
    );
    await _mqttClient.connect();
  }

  Future<void> getImageFromSource(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) {
      return;
    }
    setState(() {
      _image = File(pickedFile.path);
      InputImage inputImage = InputImage.fromFilePath(pickedFile.path);
      textRecognize(inputImage);
      _borderColor = null; // Reset border color
    });
  }

  // text recognize use google ml kit
  Future<void> textRecognize(InputImage inputImage) async {
    List<String> listText = [];
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        listText.add(line.text);
      }
    }
    setState(() {
      _textRecognized = _getSeal(listText);
      _textController.text = _textRecognized; // Update the text controller
    });
  }

  void _sendMessage(String seal) async {
    if (seal.isEmpty || _image.path.isEmpty) {
      showErrorMessage(
          context: context, message: "Please choose an image and enter seal");
      return;
    }
    //resize image if image width > _maxHeight
    Uint8List imageData = await _image.readAsBytes();
    img.Image originalImage = img.decodeImage(imageData)!;
    img.Image resizedImage = originalImage;
   if (originalImage.height > _maxHeight)
   {    
    double aspectRatio = originalImage.height / originalImage.width;
    int newWidth = (_maxHeight / aspectRatio).round();
    int newHeight = _maxHeight;
    resizedImage = img.copyResize(originalImage, width: newWidth, height: newHeight);
   }
    
    // convert image to bytes
    final bytes = img.encodeJpg(resizedImage);
    final base64Image = base64Encode(bytes);
    Map<String, String> message = {
      'seal': seal,
      'image': base64Image,
      'messageType': 'seal'
    };

    try {
      _mqttClient.sendMessage(message);
      // Assume 0 is success status
      setState(() {
        _borderColor = Colors.green; // Set to green if success
      });
    } catch (e) {
      print("Error send mqtt: $e");
      _mqttClient.disconnect();
      setState(() {
        _borderColor = Colors.red; // Set to red if failure
      });
    }
  }

  String _getSeal(List<String> listText) {
    // converts 0 to 0 and filter seal which line contains >= 6 numbers
    listText = listText
        .map((e) => e.replaceAll(RegExp(r'[oO]'), '0'))
        .where((element) => element.contains(RegExp(r'\d{6,}')))
        .toList();
    final seal = listText.isNotEmpty ? listText.first : '';
    return seal;
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('laneId');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Lane ID: $laneId'),
        actions: <Widget>[
          Row(
            children: [
              //icon refresh
              IconButton(
                onPressed: () {
                  _loadTopic();
                },
                icon: const Icon(Icons.refresh),
              ),
              //icon logout
              IconButton(
                onPressed: () {
                  _logout();
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // image holder container with icon image with full width and height
                Container(
                  margin: const EdgeInsets.all(20),
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height / 2.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _image.path == ''
                      ? Icon(Icons.image,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: PhotoView(
                            imageProvider: FileImage(_image),
                            basePosition: Alignment.center,
                            initialScale: PhotoViewComputedScale.contained,
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 2,
                          ),
                        ),
                ),
                // space between image and button
                const SizedBox(height: 20),
                // button choose camera or gallery
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    // choose camera button
                    ElevatedButton(
                        onPressed: () {
                          getImageFromSource(ImageSource.camera);
                        },
                        child: Text('Take a photo',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface,
                                fontWeight: FontWeight.bold))),
                    // choose image button
                    ElevatedButton(
                      onPressed: () {
                        getImageFromSource(ImageSource.gallery);
                      },
                      child: Text('Choose an image',
                          style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.inverseSurface,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                // space between button and text
                const SizedBox(height: 20),
                // text input seal and send button
                Column(
                  children: [
                    // container text input seal
                    Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _borderColor ??
                              Theme.of(context).colorScheme.inverseSurface,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        cursorColor:
                            Theme.of(context).colorScheme.inverseSurface,
                        controller: _textController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Enter seal',
                          border: InputBorder.none,
                          labelStyle: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.inverseSurface),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // space between text input and button
                    const SizedBox(height: 10),
                    // send button
                    ElevatedButton(
                      onPressed: () {
                        _sendMessage(_textController.text);
                      },
                      child: Text('Send',
                          style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.inverseSurface,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
