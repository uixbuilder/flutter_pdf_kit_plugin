import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_pdf_kit_plugin/flutter_pdf_kit_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(home: PdfDemoPage());
}

class PdfDemoPage extends StatefulWidget {
  @override
  State<PdfDemoPage> createState() => _PdfDemoPageState();
}

class _PdfDemoPageState extends State<PdfDemoPage> {
  String? _pdfPath;
  int _pdfViewKey = 0;
  final _plugin = FlutterPdfKitPlugin();

  void _pickPdf() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pdfPath = result.files.single.path;
        _pdfViewKey++;
      });
    }
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.highlight),
              title: Text('Highlight'),
              onTap: () {
                Navigator.pop(ctx);
                _showHighlightSheet();
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Extract Highlights'),
              onTap: () {
                Navigator.pop(ctx);
                _showExtractSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHighlightSheet() {
    final controller = TextEditingController();
    bool enabled = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Text to highlight',
                    hintText: 'Enter text to highlight',
                  ),
                  onChanged: (v) => setSheetState(() {}),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.text.trim().isEmpty
                      ? null
                      : () async {
                          if (_pdfPath == null) return;
                          final ok = await _plugin.highlightTextInPdf(
                              _pdfPath!, controller.text.trim());
                          if (ok)
                            setState(() {
                              _pdfViewKey++;
                            }); // force refresh
                          Navigator.pop(context);
                        },
                  child: Text('Highlight'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExtractSheet() async {
    if (_pdfPath == null) return;
    final highlights = await _plugin.extractHighlightedText(_pdfPath!);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Extracted Highlights',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            if (highlights != null && highlights.isNotEmpty)
              ...highlights.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(t),
                  ))
            else
              Text('No highlights found.'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('PDF Highlight Tester'),
          actions: [
            if (_pdfPath != null)
              IconButton(
                icon: Icon(Icons.menu),
                onPressed: _showMenu,
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _pickPdf,
          child: Icon(Icons.attach_file),
          tooltip: 'Select PDF',
        ),
        body: _pdfPath == null
            ? Center(child: Text('Pick a PDF to start'))
            : PDFView(
                key: ValueKey(_pdfViewKey),
                filePath: _pdfPath,
                swipeHorizontal: false,
                autoSpacing: false,
                pageFling: false,
              ),
      );
}
