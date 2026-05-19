enum ImageSourceType { local, smb, archive }

class ImageFile {
  final String name;
  final String path;
  final ImageSourceType sourceType;
  final String? archivePath;
  final String? smbConnectionId;
  final List<int>? cachedBytes;

  ImageFile({
    required this.name,
    required this.path,
    required this.sourceType,
    this.archivePath,
    this.smbConnectionId,
    this.cachedBytes,
  });

  static const supportedExtensions = ['png', 'jpg', 'jpeg', 'webp'];
  static const supportedArchives = ['zip', 'cbz'];

  static bool isSupported(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return supportedExtensions.contains(ext);
  }

  static bool isArchive(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return supportedArchives.contains(ext);
  }
}
