import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DijitalCerceveApp());
}

class DijitalCerceveApp extends StatelessWidget {
  const DijitalCerceveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dijital Çerçeve',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
      ),
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<String> _resimler = [];
  String? _klasor;
  int _saniye = 5;

  static const List<int> _sureler = [3, 5, 10, 15, 30, 60, 300];
  static const List<String> _uzantilar = [
    '.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif'
  ];

  String _sureYazi(int s) => s >= 60 ? '${s ~/ 60} dakika' : '$s saniye';

  void _mesaj(String metin) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(metin)));
  }

  Future<void> _gozat() async {
    try {
      // Depolama izni iste (eski Android'de zorunlu)
      await [Permission.storage, Permission.photos].request();

      final klasor = await FilePicker.platform.getDirectoryPath();
      if (klasor == null) return;

      final liste = <String>[];
      await for (final e in Directory(klasor).list(followLinks: false)) {
        if (e is File) {
          final yol = e.path.toLowerCase();
          if (_uzantilar.any(yol.endsWith)) liste.add(e.path);
        }
      }
      liste.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _klasor = klasor;
        _resimler = liste;
      });
      if (liste.isEmpty) _mesaj('Bu klasörde resim bulunamadı');
    } catch (e) {
      _mesaj('Klasör okunamadı. Depolama iznini kontrol edin.');
    }
  }

  void _yayinla() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SlaytSayfasi(resimler: _resimler, saniye: _saniye),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 64),
                    const SizedBox(height: 8),
                    const Text(
                      'Dijital Çerçeve',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.tonalIcon(
                      onPressed: _gozat,
                      icon: const Icon(Icons.folder_open),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Gözat', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _klasor == null
                          ? 'Henüz klasör seçilmedi'
                          : '$_klasor\n${_resimler.length} resim bulundu',
                      textAlign: TextAlign.center,
                    ),
                    if (_resimler.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _resimler.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_resimler[i]),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              cacheWidth: 150,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 72,
                                height: 72,
                                child: Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    const Text('Resim geçiş zamanı'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _saniye,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      items: _sureler
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(_sureYazi(s)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _saniye = v ?? 5),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _resimler.isEmpty ? null : _yayinla,
                      icon: const Icon(Icons.play_arrow),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Yayınla', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SlaytSayfasi extends StatefulWidget {
  final List<String> resimler;
  final int saniye;

  const SlaytSayfasi({super.key, required this.resimler, required this.saniye});

  @override
  State<SlaytSayfasi> createState() => _SlaytSayfasiState();
}

class _SlaytSayfasiState extends State<SlaytSayfasi> {
  int _index = 0;
  Timer? _zamanlayici;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _zamanlayici = Timer.periodic(Duration(seconds: widget.saniye), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.resimler.length);
    });
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: () => Navigator.of(context).pop(), // çift dokun: çık
        child: SizedBox.expand(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Image.file(
              File(widget.resimler[_index]),
              key: ValueKey(_index),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              cacheWidth: 1600,
              errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.broken_image, size: 64)),
            ),
          ),
        ),
      ),
    );
  }
}
