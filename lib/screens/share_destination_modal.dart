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
          backgroundColor: AppTheme.whatsappTeal,
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
        color: AppTheme.darkAppBar,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.whatsappTeal.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: AppTheme.whatsappGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Forward to Google Drive Chat',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.inputPill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_rounded, color: AppTheme.whatsappTeal, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      files.map((f) => f.path.split(Platform.pathSeparator).last).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Select destination chat folder:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),

            if (_isUploading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppTheme.whatsappTeal),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.cardElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: const Icon(Icons.folder_rounded, color: AppTheme.whatsappGreen, size: 20),
                      ),
                      title: Text(
                        chat.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                      trailing: const Icon(Icons.send_rounded, color: AppTheme.whatsappTeal, size: 18),
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
