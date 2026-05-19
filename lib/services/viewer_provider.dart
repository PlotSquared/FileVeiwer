import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/image_file.dart';
import '../models/smb_connection.dart';
import '../services/archive_service.dart';
import '../services/smb_service.dart';

class ViewerProvider extends ChangeNotifier {
  final ArchiveService _archiveService = ArchiveService();
  final SmbService _smbService = SmbService();

  List<ImageFile> _images = [];
  int _currentIndex = 0;
  double _rotation = 0;
  bool _isLoading = false;
  String? _error;

  List<ImageFile> get images => _images;
  int get currentIndex => _currentIndex;
  double get rotation => _rotation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasImages => _images.isNotEmpty;
  ImageFile? get currentImage => _images.isNotEmpty ? _images[_currentIndex] : null;

  Future<void> openLocalFolder() async {
    try {
      _setLoading(true);
      _error = null;
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) return;

      final dir = Directory(result);
      final entries = await dir.list().toList();

      _images = entries
          .whereType<File>()
          .where((f) => ImageFile.isSupported(f.path.split(Platform.pathSeparator).last))
          .map((f) => ImageFile(
                name: f.path.split(Platform.pathSeparator).last,
                path: f.path,
                sourceType: ImageSourceType.local,
              ))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      _currentIndex = 0;
      _rotation = 0;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> openArchive() async {
    try {
      _setLoading(true);
      _error = null;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'cbz'],
      );
      if (result == null) return;

      _images = await _archiveService.listImagesInArchive(result.files.single.path!);
      _currentIndex = 0;
      _rotation = 0;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> openSmb(SmbConnection conn, String remotePath) async {
    try {
      _setLoading(true);
      _error = null;
      _images = await _smbService.listFiles(conn, remotePath);
      _currentIndex = 0;
      _rotation = 0;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Uint8List?> loadCurrentImageBytes() async {
    final img = currentImage;
    if (img == null) return null;

    if (img.sourceType == ImageSourceType.archive) {
      return Uint8List.fromList(await _archiveService.readImageBytes(img));
    } else if (img.sourceType == ImageSourceType.smb) {
      final connections = await _smbService.loadConnections();
      final conn = connections.firstWhere((c) => c.id == img.smbConnectionId);
      return await _smbService.readFileBytes(conn, img);
    } else {
      return File(img.path).readAsBytes();
    }
  }

  void next() {
    if (_images.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _images.length;
    _rotation = 0;
    notifyListeners();
  }

  void previous() {
    if (_images.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _images.length) % _images.length;
    _rotation = 0;
    notifyListeners();
  }

  void goTo(int index) {
    if (index < 0 || index >= _images.length) return;
    _currentIndex = index;
    _rotation = 0;
    notifyListeners();
  }

  void rotateClockwise() {
    _rotation = (_rotation + 90) % 360;
    notifyListeners();
  }

  void rotateCounterClockwise() {
    _rotation = (_rotation - 90 + 360) % 360;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
