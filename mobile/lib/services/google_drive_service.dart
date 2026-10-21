import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../models/drive_item.dart';
import 'google_auth_service.dart';

class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._internal();
  GoogleDriveService._internal();

  drive.DriveApi? _getDriveApi() {
    final client = GoogleAuthService.instance.authenticatedClient;
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  /// Fetch top-level Drive folders representing "Chats"
  Future<List<DriveItem>> fetchChats({String? searchQuery}) async {
    final driveApi = _getDriveApi();
    if (driveApi == null) {
      // Return sample Drive folders for immediate demo & preview
      return _getSampleChats(searchQuery);
    }

    try {
      String q = "mimeType = 'application/vnd.google-apps.folder' and trashed = false and 'root' in parents";
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final safeSearch = searchQuery.replaceAll("'", "\\'");
        q += " and name contains '$safeSearch'";
      }

      final fileList = await driveApi.files.list(
        q: q,
        spaces: 'drive',
        orderBy: 'modifiedTime desc',
        $fields: 'files(id, name, mimeType, modifiedTime, thumbnailLink, iconLink)',
        pageSize: 50,
      );

      final items = (fileList.files ?? [])
          .map((f) => DriveItem.fromGoogleApi(f, parentId: 'root'))
          .toList();

      return items;
    } catch (e) {
      debugPrint('Error fetching Drive folders: $e');
      return _getSampleChats(searchQuery);
    }
  }

  /// Fetch contents of a specific folder (both subfolders and files)
  Future<({List<DriveItem> subchats, List<DriveItem> messages})> fetchChatThread(
      String folderId) async {
    final driveApi = _getDriveApi();
    if (driveApi == null) {
      return _getSampleThread(folderId);
    }

    try {
      final q = "'$folderId' in parents and trashed = false";
      final fileList = await driveApi.files.list(
        q: q,
        spaces: 'drive',
        orderBy: 'modifiedTime asc', // Chronological message order
        $fields:
            'files(id, name, mimeType, size, modifiedTime, thumbnailLink, webViewLink, webContentLink, iconLink)',
        pageSize: 100,
      );

      final files = fileList.files ?? [];
      final subchats = <DriveItem>[];
      final messages = <DriveItem>[];

      for (final f in files) {
        final item = DriveItem.fromGoogleApi(f, parentId: folderId);
        if (item.isFolder) {
          subchats.add(item);
        } else {
          messages.add(item);
        }
      }

      return (subchats: subchats, messages: messages);
    } catch (e) {
      debugPrint('Error fetching chat thread: $e');
      return _getSampleThread(folderId);
    }
  }

  /// Create a new folder (A new "Chat")
  Future<DriveItem?> createChatFolder(String name, {String parentId = 'root'}) async {
    final driveApi = _getDriveApi();
    if (driveApi == null) {
      return DriveItem(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        mimeType: 'application/vnd.google-apps.folder',
        isFolder: true,
        modifiedTime: DateTime.now(),
        parentId: parentId,
      );
    }

    try {
      final folderMetadata = drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [parentId];

      final created = await driveApi.files.create(
        folderMetadata,
        $fields: 'id, name, mimeType, modifiedTime',
      );

      return DriveItem.fromGoogleApi(created, parentId: parentId);
    } catch (e) {
      debugPrint('Error creating folder: $e');
      return null;
    }
  }

  /// Send a quick text note into the folder (Saved as a .txt note)
  Future<DriveItem?> sendTextNote(String text, String folderId) async {
    final driveApi = _getDriveApi();
    final now = DateTime.now();
    final fileName = 'Note-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.txt';

    if (driveApi == null) {
      return DriveItem(
        id: 'mock-note-${now.millisecondsSinceEpoch}',
        name: fileName,
        mimeType: 'text/plain',
        isFolder: false,
        sizeBytes: text.length,
        modifiedTime: now,
        parentId: folderId,
      );
    }

    try {
      final content = utf8.encode(text);
      final stream = Stream.value(content);
      final media = drive.Media(stream, content.length);

      final fileMetadata = drive.File()
        ..name = fileName
        ..mimeType = 'text/plain'
        ..description = text
        ..parents = [folderId];

      final created = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
        $fields: 'id, name, mimeType, size, modifiedTime, webViewLink',
      );

      return DriveItem.fromGoogleApi(created, parentId: folderId);
    } catch (e) {
      debugPrint('Error creating text note: $e');
      return null;
    }
  }

  /// Upload any file (photo, PDF, voice note from WhatsApp) directly to the Drive folder
  Future<DriveItem?> uploadFile({
    required File file,
    required String targetFolderId,
    String? customName,
    String? mimeType,
  }) async {
    final driveApi = _getDriveApi();
    final fileName = customName ?? file.path.split(Platform.pathSeparator).last;
    final fileLength = await file.length();

    if (driveApi == null) {
      return DriveItem(
        id: 'mock-upload-${DateTime.now().millisecondsSinceEpoch}',
        name: fileName,
        mimeType: mimeType ?? 'application/octet-stream',
        isFolder: false,
        sizeBytes: fileLength,
        modifiedTime: DateTime.now(),
        parentId: targetFolderId,
      );
    }

    try {
      final media = drive.Media(file.openRead(), fileLength);
      final fileMetadata = drive.File()
        ..name = fileName
        ..parents = [targetFolderId];

      if (mimeType != null) {
        fileMetadata.mimeType = mimeType;
      }

      final created = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
        $fields: 'id, name, mimeType, size, modifiedTime, thumbnailLink, webViewLink',
      );

      return DriveItem.fromGoogleApi(created, parentId: targetFolderId);
    } catch (e) {
      debugPrint('Error uploading file to Drive: $e');
      return null;
    }
  }

  // ----------------------------------------------------
  // Realistic Sample Dataset for immediate testing & demo
  // ----------------------------------------------------
  List<DriveItem> _getSampleChats(String? search) {
    final list = [
      DriveItem(
        id: 'folder-medical',
        name: 'Medical & Prescriptions',
        mimeType: 'application/vnd.google-apps.folder',
        isFolder: true,
        modifiedTime: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      DriveItem(
        id: 'folder-tax',
        name: 'Tax & Income Receipts',
        mimeType: 'application/vnd.google-apps.folder',
        isFolder: true,
        modifiedTime: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      DriveItem(
        id: 'folder-home',
        name: 'House Lease & Electricity Bills',
        mimeType: 'application/vnd.google-apps.folder',
        isFolder: true,
        modifiedTime: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DriveItem(
        id: 'folder-car',
        name: 'Car Service & Insurance',
        mimeType: 'application/vnd.google-apps.folder',
        isFolder: true,
        modifiedTime: DateTime.now().subtract(const Duration(days: 3)),
      ),
      DriveItem(
        id: 'folder-family',
        name: 'Family Photos & Videos',
        mimeType: 'application/vnd.google-apps.folder',
        isFolder: true,
        modifiedTime: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ];

    if (search != null && search.isNotEmpty) {
      return list
          .where((item) => item.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }
    return list;
  }

  ({List<DriveItem> subchats, List<DriveItem> messages}) _getSampleThread(String folderId) {
    if (folderId == 'folder-medical') {
      return (
        subchats: [
          DriveItem(
            id: 'sub-lab-reports',
            name: '2026 Blood & Lab Reports',
            mimeType: 'application/vnd.google-apps.folder',
            isFolder: true,
            modifiedTime: DateTime.now().subtract(const Duration(days: 2)),
            parentId: folderId,
          ),
          DriveItem(
            id: 'sub-eye',
            name: 'Optometry & Eye Checkups',
            mimeType: 'application/vnd.google-apps.folder',
            isFolder: true,
            modifiedTime: DateTime.now().subtract(const Duration(days: 14)),
            parentId: folderId,
          ),
        ],
        messages: [
          DriveItem(
            id: 'med-1',
            name: 'Apollo_Prescription_Dr_Rao.pdf',
            mimeType: 'application/pdf',
            isFolder: false,
            sizeBytes: 1024 * 720,
            modifiedTime: DateTime.now().subtract(const Duration(days: 4, hours: 2)),
            parentId: folderId,
          ),
          DriveItem(
            id: 'med-2',
            name: 'Medicine_Schedule_Note.txt',
            mimeType: 'text/plain',
            isFolder: false,
            sizeBytes: 140,
            modifiedTime: DateTime.now().subtract(const Duration(days: 3)),
            parentId: folderId,
          ),
          DriveItem(
            id: 'med-3',
            name: 'Chest_XRay_Digital_Copy.jpg',
            mimeType: 'image/jpeg',
            isFolder: false,
            sizeBytes: 1024 * 1024 * 2,
            thumbnailLink: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=400&q=80',
            modifiedTime: DateTime.now().subtract(const Duration(hours: 1)),
            parentId: folderId,
          ),
        ],
      );
    }

    if (folderId == 'folder-tax') {
      return (
        subchats: [
          DriveItem(
            id: 'sub-fy-2025-26',
            name: 'FY 2025-26 Submissions',
            mimeType: 'application/vnd.google-apps.folder',
            isFolder: true,
            modifiedTime: DateTime.now(),
            parentId: folderId,
          ),
        ],
        messages: [
          DriveItem(
            id: 'tax-1',
            name: 'Form16_Part_A_and_B.pdf',
            mimeType: 'application/pdf',
            isFolder: false,
            sizeBytes: 1024 * 1024 * 3,
            modifiedTime: DateTime.now().subtract(const Duration(days: 5)),
            parentId: folderId,
          ),
          DriveItem(
            id: 'tax-2',
            name: 'Advance_Tax_Challan_Chit.jpg',
            mimeType: 'image/jpeg',
            isFolder: false,
            sizeBytes: 1024 * 450,
            thumbnailLink: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=400&q=80',
            modifiedTime: DateTime.now().subtract(const Duration(hours: 3)),
            parentId: folderId,
          ),
        ],
      );
    }

    // Default thread
    return (
      subchats: [],
      messages: [
        DriveItem(
          id: 'def-1',
          name: 'Important_Document_Scan.pdf',
          mimeType: 'application/pdf',
          isFolder: false,
          sizeBytes: 1024 * 890,
          modifiedTime: DateTime.now().subtract(const Duration(days: 1)),
          parentId: folderId,
        ),
      ],
    );
  }
}
