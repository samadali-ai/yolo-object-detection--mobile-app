import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLOv5 Object Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(secondary: Colors.orange), // Set accent color
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<XFile> _imageFiles = [];
  List<Map<String, dynamic>> _results = [];
  bool _enableAdvancedDetection = false;

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _imageFiles = pickedFiles;
        _results.clear(); // Clear previous results
      });

      for (var file in _imageFiles) {
        await _detectObjects(file);
      }
    }
  }

  Future<void> _detectObjects(XFile file) async {
    final Uri url = Uri.parse('https://3aee-2401-4900-33d5-7ad5-c659-b5d7-a2f5-e321.ngrok-free.app/detect');
    final request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('image', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final result = json.decode(responseData);
      setState(() {
        _results.add(result);
      });
    } else {
      // Handle errors here
      print('Error: ${response.statusCode}');
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YOLOv5 Object Detection'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Info"),
                  content: Text("Select images to detect objects and classify the room type."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("OK"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Advanced Detection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _enableAdvancedDetection,
                    onChanged: (bool value) {
                      setState(() {
                        _enableAdvancedDetection = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImages,
                child: Text('Pick Images'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 16),
              _imageFiles.isEmpty
                  ? Center(child: Text('No images selected.', style: TextStyle(fontSize: 16)))
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _imageFiles.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5.0,
                                spreadRadius: 1.0,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.file(
                                  File(_imageFiles[index].path),
                                  fit: BoxFit.cover,
                                  height: 120,
                                  width: double.infinity,
                                ),
                              ),
                              SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _results.length > index
                                          ? _results[index]['room_type'] ?? 'Unknown'
                                          : 'Processing...',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _results.length > index
                                          ? 'Detected: ${(_results[index]['detected_objects'] as List).join(', ')}'
                                          : '',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(thickness: 1, color: Colors.blueAccent),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.check, color: Colors.green),
                                    Text(
                                      'Confidence: ${_results.length > index ? (_results[index]['confidence']?.toString() ?? 'N/A') : 'N/A'}',
                                      style: TextStyle(fontSize: 14, color: Colors.blueAccent),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
