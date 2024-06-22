import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart'; // Import the google_fonts package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FontMergerDemo(),
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

class FontMergerDemo extends StatefulWidget {
  @override
  _FontMergerDemoState createState() => _FontMergerDemoState();
}

class _FontMergerDemoState extends State<FontMergerDemo> {
  String? _selectedFont1;
  String? _selectedFont2;
  List<String>? _outputImages;
  Uint8List? _fontData;
  bool _isLoading = false;
  String? _loadingMessage;
  bool _fontDownloaded = false;
  bool _tryItOutEnabled = false;
  TextEditingController _textController = TextEditingController();

  PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;

  List<String> _fontOptions = [
    'Lora',
    'Amatic SC',
    'Sanchez',
    'Caveat',
    'Comfortaa',
    'Roboto Serif',
    'Open Sans',
    'EB Garamond',
    'Ubuntu',
    'Inter',
    'Corben',
    'Lexend',
    'Lobster',
    'Merriweather',
    'Montserrat',
    'Nunito',
    'Pacifico',
    'Oswald',
    'Playfair Display',
    'Roboto',
    'Roboto Mono',
    'Quicksand',
    'Spectral',
    'Oxygen',
    'Assistant',
  ];

  List<String> _filteredFontOptions = [];

  final List<String> _loadingMessages = [
    'Converting font into latent spaces....',
    'Interpolating the Latent Spaces........',
    'Generating Hybrid Font'
  ];

  @override
  void initState() {
    super.initState();
    _filteredFontOptions = List<String>.from(_fontOptions);
  }

  void _updateFilteredOptions() {
    if (_selectedFont1 != null) {
      _filteredFontOptions =
          _fontOptions.where((font) => font != _selectedFont1).toList();
    } else {
      _filteredFontOptions = List<String>.from(_fontOptions);
    }
  }

  final storage = FlutterSecureStorage();

  Future<void> _sendFonts() async {
    if (_selectedFont1 != null && _selectedFont2 != null) {
      setState(() {
        _isLoading = true;
        _fontDownloaded = false;
      });

      for (int i = 0; i < _loadingMessages.length; i++) {
        await Future.delayed(Duration(seconds: 2), () {
          setState(() {
            _loadingMessage = _loadingMessages[i];
          });
        });
      }

      await Future.delayed(Duration(seconds: 2));

      String? token = await storage.read(key: 'authToken');
      var headers = {
        'Authorization': 'Token $token',
        'Content-Type': 'multipart/form-data',
      };

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://stable-simply-porpoise.ngrok-free.app/image_process_api/'),
      )..headers.addAll(headers);

      request.fields['image1'] = _selectedFont1!;
      request.fields['image2'] = _selectedFont2!;

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        setState(() {
          _outputImages = List<String>.from(jsonResponse['output_images']);
        });
      } else {
        print('Failed to send fonts: ${response.statusCode}');
      }

      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    } else {
      print('Both fonts are required');
    }
  }

  Future<void> _fetchFont() async {
    print('Fetching font...');
    try {
      // Retrieve the token from secure storage
      String? token = await storage.read(key: 'authToken');

      // Include the token in the request headers
      var response = await http.get(
        Uri.parse('https://stable-simply-porpoise.ngrok-free.app/get-font/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        print('TTF file fetched successfully');

        String fileName =
            Uri.parse('https://stable-simply-porpoise.ngrok-free.app/get-font/')
                .pathSegments
                .last;
        print('Fetched file name: $fileName');

        // Get the directory to store the file
        var documentDirectory = await getApplicationDocumentsDirectory();
        File file = File('${documentDirectory.path}/Pranavaa-Regular.ttf');

        // Write the file
        await file.writeAsBytes(response.bodyBytes);

        // Load the font directly from the file
        final fontLoader = FontLoader('CustomFont');
        fontLoader
            .addFont(Future.value(ByteData.sublistView(response.bodyBytes)));
        await fontLoader.load();

        setState(() {
          _fontData = response.bodyBytes;
          _fontDownloaded = true;
          _currentIndex =
              1; // Automatically switch to the "Try it out!" section
          _pageController.jumpToPage(1);
        });
      } else {
        print('Failed to fetch font: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching font: $e');
    }
  }

  Future<void> _loadFont() async {
    if (_fontData != null) {
      final fontLoader = FontLoader('CustomFont');
      fontLoader.addFont(Future.value(ByteData.view(_fontData!.buffer)));
      await fontLoader.load();
      print('Custom font loaded');
    } else {
      print('Font data is null');
    }
  }

  Future<void> savePdfInDownloads(Uint8List pdfBytes, String fileName) async {
    await Permission.storage.request();
    final String dirPath = '/storage/emulated/0/Download';
    final File file = File('$dirPath/$fileName');

    await file.writeAsBytes(pdfBytes, flush: true);
    print("File saved to $dirPath");
  }

  Future<void> _downloadAsPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Center(
        child: pw.Text("Hello World"),
      );
    }));

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/example.pdf");
    await file.writeAsBytes(await pdf.save());

    await savePdfInDownloads(await pdf.save(), 'example.pdf');
  }

  @override
  Widget build(BuildContext context) {
    _updateFilteredOptions();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 114, 158, 193),
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Font Merger Demo',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: _tryItOutEnabled
            ? AlwaysScrollableScrollPhysics()
            : NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildFontBlenderPage(),
          _buildTryItOutPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.merge_type),
            label: 'Font Blender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.text_fields),
            label: 'Try it out!',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_tryItOutEnabled || index == 0) {
            _pageController.animateToPage(index,
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          }
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        unselectedLabelStyle: TextStyle(color: Colors.grey),
        selectedLabelStyle: TextStyle(color: Colors.blue),
      ),
    );
  }

  Widget _buildFontBlenderPage() {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 250, 250, 251), // Set background color here
      ), // Set background color
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 10, 70, 118),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset:
                                  Offset(0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          itemCount: _fontOptions.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                _fontOptions[index],
                                style: GoogleFonts.getFont(
                                  _fontOptions[index],
                                  textStyle: TextStyle(
                                    color:
                                        Colors.white, // Set text color to white
                                    fontWeight:
                                        FontWeight.bold, // Set text to bold
                                  ),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedFont1 = _fontOptions[index];
                                  _filteredFontOptions = _fontOptions
                                      .where((font) => font != _selectedFont1)
                                      .toList();
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 10, 70, 118),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset:
                                  Offset(0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          itemCount: _filteredFontOptions.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                _filteredFontOptions[index],
                                style: GoogleFonts.getFont(
                                  _filteredFontOptions[index],
                                  textStyle: TextStyle(
                                    color:
                                        Colors.white, // Set text color to white
                                    fontWeight:
                                        FontWeight.bold, // Set text to bold
                                  ),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedFont2 = _filteredFontOptions[index];
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                if (_selectedFont1 != null && _selectedFont2 != null)
                  Column(
                    children: [
                      Text(
                        'Selected Fonts:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSelectedFontContainer(_selectedFont1!),
                          SizedBox(width: 10),
                          _buildSelectedFontContainer(_selectedFont2!),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_selectedFont1 != null && _selectedFont2 != null)
                            ? Color.fromARGB(255, 10, 70, 118)
                            : Colors.grey, // Set button color
                    foregroundColor: Colors.white, // Set text color
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    textStyle:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: (_selectedFont1 != null && _selectedFont2 != null)
                      ? _sendFonts
                      : null,
                  child: Text('Merge Fonts'),
                ),
                SizedBox(height: 20),
                if (_isLoading) ...[
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(
                    _loadingMessage ?? 'Loading...',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ],
                if (_outputImages != null) ...[
                  Text(
                    'Output Images:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _outputImages!.map((imageBase64) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Image.memory(
                            base64Decode(imageBase64),
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey,
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Color.fromARGB(255, 10, 70, 118), // Set button color
                    foregroundColor: Colors.white, // Set text color
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    textStyle:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _fetchFont();
                  },
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Download Hybrid Font'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFontContainer(String font) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 230, 230, 230),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Color.fromARGB(255, 10, 70, 118),
          width: 2,
        ),
      ),
      child: Text(
        font,
        style: GoogleFonts.getFont(
          font,
          textStyle: TextStyle(
            color: Colors.black, // Set text color to black
            fontWeight: FontWeight.bold, // Set text to bold
          ),
        ),
      ),
    );
  }

  Widget _buildTryItOutPage() {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 250, 250, 251), // Set background color here
        // image: DecorationImage(
        //   image: AssetImage('assets/background.jpg'),
        //   fit: BoxFit.cover,
        // ),
        // borderRadius: BorderRadius.circular(15), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3), // Shadow position
          ),
        ],
      ), // Set background color
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(width: 8), // Spacing between buttons
                ElevatedButton(
                  onPressed: _downloadAsPdf,
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 10, 70, 118),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25), // Rounded button
                    ),
                    padding: EdgeInsets.all(10),
                    shadowColor: Colors.grey.withOpacity(0.5), // Button shadow
                    elevation: 5, // Button elevation
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35), // Rounded text field
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.8),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 2), // Text field shadow position
                    ),
                  ],
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontFamily: _fontDownloaded ? 'CustomFont' : null,
                    fontSize: 24,
                    color: Colors.black, // Text color
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15), // Rounded border
                    ),
                    labelText: 'Enter text',

                    labelStyle: TextStyle(
                        color: Color.fromARGB(255, 66, 3, 155)), // Label color
                    hintStyle: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
