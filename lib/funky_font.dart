import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FunkyFontsPage extends StatefulWidget {
  @override
  _FunkyFontsPageState createState() => _FunkyFontsPageState();
}

class _FunkyFontsPageState extends State<FunkyFontsPage> {
  String sampleText = "This is what the font looks like";
  String userInput = "";
  Uint8List? fontData;
  String apiUrl = 'https://stable-simply-porpoise.ngrok-free.app/funky-font/';
  TextStyle? customTextStyle;
  int fontLoadCounter = 0; // Counter to ensure unique FontLoader each time

  final storage = FlutterSecureStorage();

  Future<void> fetchFont() async {
    try {
      String? token = await storage.read(key: 'authToken');
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        fontData = response.bodyBytes;
        await loadFont(fontData);
      } else {
        throw Exception('Failed to load font');
      }
    } catch (e) {
      print('Error fetching font: $e');
    }
  }

  Future<void> loadFont(Uint8List? fontData) async {
    if (fontData == null) return;

    // Increment the counter to ensure a unique font family name
    fontLoadCounter++;
    final fontLoader = FontLoader('CustomFont_$fontLoadCounter');
    fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
    await fontLoader.load();
    setState(() {
      customTextStyle = TextStyle(
        fontFamily: 'CustomFont_$fontLoadCounter',
        fontSize: 24,
      );
    });
  }

  Future<void> generatePdf(Uint8List? fontData, String text) async {
    if (fontData == null) return;

    final font = pw.Font.ttf(ByteData.sublistView(fontData));
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(
              text,
              style: pw.TextStyle(font: font, fontSize: 24),
            ),
          );
        },
      ),
    );

    final output = await pdf.save();
    await Printing.sharePdf(bytes: output, filename: 'custom_font.pdf');
  }

  Future<void> _downloadAsPdf() async {
    if (fontData == null) return;

    final pdf = pw.Document();
    final customFont = pw.Font.ttf(ByteData.sublistView(fontData!));

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(
              userInput,
              style: pw.TextStyle(font: customFont, fontSize: 24),
            ),
          );
        },
      ),
    );

    // Get the Downloads directory
    final output = await getExternalStorageDirectory();
    final downloadsPath = output?.path ?? "/storage/emulated/0/Download";
    final file = File("$downloadsPath/output.pdf");
    await file.writeAsBytes(await pdf.save());

    print("PDF saved to ${file.path}");

    // Display a message to the user
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("PDF saved to ${file.path}")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Funky Fonts'),
        backgroundColor: Color.fromARGB(255, 114, 158, 193),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (customTextStyle != null)
              Text(
                sampleText,
                style: customTextStyle,
              ),
            SizedBox(height: 20), // Add some space before the text field
            Expanded(
              // Wrap the TextField in an Expanded widget
              child: Container(
                width: MediaQuery.of(context).size.width *
                    0.7, // 70% of screen width
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      userInput = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Enter your text here',
                    border: OutlineInputBorder(), // Add an outline border
                  ),
                  style: customTextStyle,
                  maxLines: null, // Allow multiple lines
                  expands: true, // Expand vertically
                ),
              ),
            ),
            SizedBox(height: 20), // Space after the text field
            ElevatedButton(
              onPressed: fetchFont,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 114, 158, 193),
                ),
                foregroundColor: MaterialStateProperty.all<Color>(
                  Colors.black,
                ),
              ),
              child: Text('Load Font'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _downloadAsPdf();
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 114, 158, 193),
                ),
                foregroundColor: MaterialStateProperty.all<Color>(
                  Colors.black,
                ),
              ),
              child: Text('Generate and Download PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
