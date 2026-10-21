class DriveItem {
  final String id;
  final String name;
  final String mimeType;
  final bool isFolder;
  final int? sizeBytes;
  final DateTime modifiedTime;
  final String? thumbnailLink;
  final String? webViewLink;
  final String? webContentLink;
  final String? iconLink;
  final String parentId;

  DriveItem({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.isFolder,
    this.sizeBytes,
    required this.modifiedTime,
    this.thumbnailLink,
    this.webViewLink,
    this.webContentLink,
    this.iconLink,
    this.parentId = 'root',
  });

  bool get isImage =>
      mimeType.startsWith('image/') ||
      name.toLowerCase().endsWith('.png') ||
      name.toLowerCase().endsWith('.jpg') ||
      name.toLowerCase().endsWith('.jpeg') ||
      name.toLowerCase().endsWith('.webp');

  bool get isPdf =>
      mimeType == 'application/pdf' || name.toLowerCase().endsWith('.pdf');

  bool get isAudio =>
      mimeType.startsWith('audio/') ||
      name.toLowerCase().endsWith('.mp3') ||
      name.toLowerCase().endsWith('.m4a') ||
      name.toLowerCase().endsWith('.wav') ||
      name.toLowerCase().endsWith('.ogg');

  bool get isTextNote =>
      mimeType.startsWith('text/') ||
      name.toLowerCase().endsWith('.txt') ||
      name.startsWith('Note-') ||
      name.startsWith('Message-');

  String get formattedSize {
    if (sizeBytes == null || sizeBytes == 0) return '';
    final kb = sizeBytes! / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory DriveItem.fromGoogleApi(dynamic file, {String parentId = 'root'}) {
    final mime = file.mimeType ?? '';
    final isFolder = mime == 'application/vnd.google-apps.folder';
    int? parsedSize;
    if (file.size != null) {
      parsedSize = int.tryParse(file.size.toString());
    }

    DateTime modTime = DateTime.now();
    if (file.modifiedTime != null) {
      modTime = DateTime.tryParse(file.modifiedTime.toString()) ?? DateTime.now();
    }

    return DriveItem(
      id: file.id ?? '',
      name: file.name ?? 'Untitled',
      mimeType: mime,
      isFolder: isFolder,
      sizeBytes: parsedSize,
      modifiedTime: modTime,
      thumbnailLink: file.thumbnailLink,
      webViewLink: file.webViewLink,
      webContentLink: file.webContentLink,
      iconLink: file.iconLink,
      parentId: parentId,
    );
  }
}
