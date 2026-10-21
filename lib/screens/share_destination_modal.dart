import 'dart:io';
import 'package:flutter/material.dart';
import '../models/drive_item.dart';
import '../services/google_drive_service.dart';
import '../services/share_intent_service.dart';
import '../theme/app_theme.dart';

class ShareDestinationModal extends StatefulWidget {
  final SharedMediaPayload payload;
  final List<DriveItem> chats;
  final VoidCallback onFinished;

  const ShareDestinationModal({
    super.key,
    required this.payload,
    required this.chats,
    required this.onFinished,
  });

  @override
  State<ShareDestinationModal> createState() => _ShareDestinationModalState();
}

class _ShareDestinationModalState extends State<ShareDestinationModal> {
  bool _isUploading = false;
  String _uploadStatus = '';

  Future<void> _sendToChat(DriveItem chat) async {
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Saving to "${chat.name}"...';
    });

    final files = widget.payload.files;
    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      setState(() {
        _uploadStatus = 'Uploading ${i + 1} of ${files.length} to "${chat.name}"...';
      });

      await GoogleDriveService.instance.uploadFile(
        file: File(f.path),
        targetFolderId: chat.id,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Saved ${files.length} item(s) to "${chat.name}" in Google Drive!'),
          backgroundColor: AppTheme.whatsappGreen,
        ),
      );
      Navigator.pop(context);
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.payload.files;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.whatsappGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: AppTheme.whatsappGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Forwarded from WhatsApp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${files.length} file(s) ready to organize into Google Drive',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // File preview chip
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cardElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_rounded, color: AppTheme.primaryEmerald, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      files.map((f) => f.path.split(Platform.pathSeparator).last).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Select which chat to send this to:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),

            if (_isUploading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppTheme.whatsappGreen),
                      const SizedBox(height: 14),
                      Text(_uploadStatus, style: const TextStyle(color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.chats.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1, color: AppTheme.cardBorder),
                  itemBuilder: (ctx, i) {
                    final chat = widget.chats[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.cardElevated,
                        child: const Icon(Icons.folder_rounded, color: AppTheme.whatsappGreen, size: 20),
                      ),
                      title: Text(
                        chat.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                      trailing: const Icon(Icons.send_rounded, color: AppTheme.whatsappGreen, size: 18),
                      onTap: () => _sendToChat(chat),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
