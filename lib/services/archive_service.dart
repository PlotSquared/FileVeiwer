import 'dart:io';
import 'package:archive/archive.dart';
import '../models/image_file.dart';

class ArchiveService {
  Future<List<ImageFile>> listImagesInArchive(String archivePath) async {
    final bytes = await File(archivePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final images = archive.files
        .where((f) => !f.isDirectory && ImageFile.isSupported(f.name.split('/').last))
        .map((f) => ImageFile(
              name: f.name.split('/').last,
              path: archivePath,
              sourceType: ImageSourceType.archive,
              archivePath: f.name,
              cachedBytes: f.content as List<int>?,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return images;
  }

  Future<List<int>> readImageBytes(ImageFile file) async {
    if (file.cachedBytes != null) return file.cachedBytes!;

    final bytes = await File(file.path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final entry = archive.files.firstWhere(
      (f) => f.name == file.archivePath,
      orElse: () => throw Exception('파일을 찾을 수 없음: ${file.archivePath}'),
    );

    return entry.content as List<int>;
  }
}
