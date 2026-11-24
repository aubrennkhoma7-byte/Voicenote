import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

void main() => runApp(const VoiceNoteApp());

class VoiceNoteApp extends StatefulWidget {
  const VoiceNoteApp({super.key});
  @override
  State<VoiceNoteApp> createState() => _VoiceNoteAppState();
}

class _VoiceNoteAppState extends State<VoiceNoteApp> {
  bool isDark = true;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VoiceNote',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        isDark: isDark,
        onToggle: () => setState(() => isDark = !isDark),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const HomePage({super.key, required this.isDark, required this.onToggle});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final recorder = AudioRecorder();
  bool isRecording = false;
  String? audioPath;
  List<File> recordings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.m4a')).toList();
    setState(() => recordings = files);
  }

  Future<void> _toggleRecord() async {
    if (isRecording) {
      final path = await recorder.stop();
      setState(() { isRecording = false; audioPath = path; });
      _load();
    } else {
      if (await recorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/voicenote_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await recorder.start(const RecordConfig(), path: path);
        setState(() => isRecording = true);
      }
    }
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (c) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('VoiceNote Recordings', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        ...recordings.map((f) => pw.Text('- ${f.path.split('/').last}')),
      ],
    )));
    final dir = await getApplicationDocumentsDirectory();
    final out = File('${dir.path}/VoiceNote_List.pdf');
    await out.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(out.path)], text: 'My VoiceNote recordings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VoiceNote'),
        actions: [
          IconButton(icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode), onPressed: widget.onToggle),
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportPdf),
        ],
      ),
      body: recordings.isEmpty
          ? const Center(child: Text('No recordings yet.\nTap Record to start.', textAlign: TextAlign.center))
          : ListView.builder(
              itemCount: recordings.length,
              itemBuilder: (c, i) => ListTile(
                leading: const Icon(Icons.mic),
                title: Text(recordings[i].path.split('/').last),
                trailing: IconButton(icon: const Icon(Icons.share), onPressed: () => Share.shareXFiles([XFile(recordings[i].path)])),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleRecord,
        icon: Icon(isRecording ? Icons.stop : Icons.mic),
        label: Text(isRecording ? 'Stop' : 'Record'),
        backgroundColor: isRecording ? Colors.red : null,
      ),
    );
  }
}
