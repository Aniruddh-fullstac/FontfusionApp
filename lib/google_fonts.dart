import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GoogleFontsPage extends StatefulWidget {
  @override
  _GoogleFontsPageState createState() => _GoogleFontsPageState();
}

class _GoogleFontsPageState extends State<GoogleFontsPage> {
  TextEditingController _textEditingController = TextEditingController();
  String _selectedFont = 'Roboto';
  double _fontSize = 16;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;
  TextAlign _textAlign = TextAlign.left;

  final List<String> _fonts = [
    'Roboto',
    'Lato',
    'Oswald',
    'Montserrat',
    'Open Sans',
    'Raleway',
    'Merriweather',
    'Nunito',
    'Poppins',
    'Playfair Display',
    'Ubuntu',
    'Quicksand',
    'Karla',
    'Rubik',
    'Source Sans Pro',
  ];

  TextStyle _getTextStyle() {
    return GoogleFonts.getFont(
      _selectedFont,
      fontSize: _fontSize,
      fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
      decoration:
          _isUnderlined ? TextDecoration.underline : TextDecoration.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Fonts Editor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedFont,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFont = newValue;
                        });
                      }
                    },
                    items: _fonts.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<double>(
                    value: _fontSize,
                    onChanged: (double? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _fontSize = newValue;
                        });
                      }
                    },
                    items: List<double>.generate(50, (index) => index + 8.0)
                        .map<DropdownMenuItem<double>>((double value) {
                      return DropdownMenuItem<double>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isBold ? Icons.format_bold : Icons.format_bold_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _isBold = !_isBold;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isItalic
                        ? Icons.format_italic
                        : Icons.format_italic_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _isItalic = !_isItalic;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    _isUnderlined
                        ? Icons.format_underline
                        : Icons.format_underline_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _isUnderlined = !_isUnderlined;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.format_align_left),
                  onPressed: () {
                    setState(() {
                      _textAlign = TextAlign.left;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.format_align_center),
                  onPressed: () {
                    setState(() {
                      _textAlign = TextAlign.center;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.format_align_right),
                  onPressed: () {
                    setState(() {
                      _textAlign = TextAlign.right;
                    });
                  },
                ),
              ],
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: TextField(
                  controller: _textEditingController,
                  style: _getTextStyle(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter your text here...',
                  ),
                  textAlign: _textAlign,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
