import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_pdf_kit_plugin/flutter_pdf_kit_plugin.dart';
import 'package:flutter_pdf_kit_plugin/highlight_option.dart';

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
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initPlatformVersion();
  }

  Future<void> _initPlatformVersion() async {
    final version = await _plugin.getPlatformVersion();
    if (!mounted) return;
    setState(() {
      _platformVersion = version ?? 'Unknown';
    });
  }

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
              leading: const Icon(Icons.list),
              title: const Text('Extract Highlights'),
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
            const Text('Extracted Highlights',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (highlights != null && highlights.isNotEmpty)
              ...highlights.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(t),
                  ))
            else
              const Text('No highlights found.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('PDF Highlight Tester'),
          actions: [
            if (_pdfPath != null)
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: _showMenu,
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _pickPdf,
          tooltip: 'Select PDF',
          child: const Icon(Icons.attach_file),
        ),
        body: _pdfPath == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pick a PDF to start'),
                    const SizedBox(height: 16),
                    Text('Running on: $_platformVersion'),
                  ],
                ),
              )
            : Theme.of(context).platform == TargetPlatform.android
                ? PDFView(
                    key: ValueKey(_pdfViewKey),
                    filePath: _pdfPath,
                    swipeHorizontal: false,
                    autoSpacing: false,
                    pageFling: false,
                  )
                : Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Open PDF in Native Viewer'),
                      onPressed: () async {
                        if (_pdfPath != null) {
                          final ok = await _plugin.editPdfUsingViewer(
                            _pdfPath!,
                            [
                              HighlightOption(
                                  tag: "character_line",
                                  name: "Character's lines",
                                  color: "#FFFF00"),
                              HighlightOption(
                                  tag: "character_name",
                                  name: "Character's name",
                                  color: "#00FF00"),
                            ],
                          );
                          if (ok) {
                            final highlights =
                                await _plugin.extractHighlightedText(_pdfPath!);
                            if (!mounted) return;
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) => Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Extracted Highlights',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    if (highlights != null &&
                                        highlights.isNotEmpty)
                                      ...highlights.map((t) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Text(t),
                                          ))
                                    else
                                      const Text('No highlights found.'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            setState(() {
                              _pdfViewKey++;
                            });
                          }
                        }
                      },
                    ),
                  ),
      );
}
