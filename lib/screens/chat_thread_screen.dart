import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/drive_item.dart';
import '../services/google_drive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/file_bubble.dart';

class ChatThreadScreen extends StatefulWidget {
  final DriveItem folder;

  const ChatThreadScreen({super.key, required this.folder});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  List<DriveItem> _subchats = [];
  List<DriveItem> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    setState(() => _isLoading = true);
    final data = await GoogleDriveService.instance.fetchChatThread(widget.folder.id);
    if (mounted) {
      setState(() {
        _subchats = data.subchats;
        _messages = data.messages;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    _msgCtrl.clear();
    setState(() => _isSending = true);

    final sent = await GoogleDriveService.instance.sendTextNote(
      text,
      widget.folder.id,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        if (sent != null) {
          _messages.add(sent);
        }
      });
      _scrollToBottom();
    }
  }

  Future<void> _handlePickAndUploadFile() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload to this Chat Folder',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.cardElevated,
                  child: Icon(Icons.photo_library_rounded, color: AppTheme.whatsappGreen),
                ),
                title: const Text('Photos & Videos'),
                subtitle: const Text('Pick from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    _uploadFilePath(image.path, mimeType: 'image/jpeg');
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.cardElevated,
                  child: Icon(Icons.camera_alt_rounded, color: Colors.blueAccent),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Capture with Camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final photo = await picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    _uploadFilePath(photo.path, mimeType: 'image/jpeg');
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.cardElevated,
                  child: Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                ),
                title: const Text('Document or PDF'),
                subtitle: const Text('Browse device files'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && result.files.single.path != null) {
                    _uploadFilePath(result.files.single.path!);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadFilePath(String path, {String? mimeType}) async {
    setState(() => _isSending = true);
    final file = File(path);

    final uploaded = await GoogleDriveService.instance.uploadFile(
      file: file,
      targetFolderId: widget.folder.id,
      mimeType: mimeType,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        if (uploaded != null) {
          _messages.add(uploaded);
        }
      });
      _scrollToBottom();
    }
  }

  void _showNewSubchatDialog() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: const Text('New Sub-Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. 2026 Scans, Archive',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.cardElevated,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = textCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final created = await GoogleDriveService.instance.createChatFolder(
                  name,
                  parentId: widget.folder.id,
                );
                if (created != null && mounted) {
                  _loadThread();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.whatsappGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.cardElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Icon(
                Icons.folder_rounded,
                color: AppTheme.whatsappGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${_messages.length} files • ${_subchats.length} sub-chats',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadThread,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sub-Chats Row (Nested Folders)
          if (_subchats.isNotEmpty || !_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: AppTheme.darkSurface,
                border: Border(
                  bottom: BorderSide(color: AppTheme.cardBorder, width: 0.8),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._subchats.map(
                      (sub) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(
                            Icons.folder_open_rounded,
                            size: 16,
                            color: AppTheme.whatsappGreen,
                          ),
                          label: Text(
                            sub.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          backgroundColor: AppTheme.cardElevated,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppTheme.cardBorder),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatThreadScreen(folder: sub),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16, color: AppTheme.primaryEmerald),
                      label: const Text(
                        'New Sub-chat',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.primaryEmerald),
                      ),
                      onPressed: _showNewSubchatDialog,
                    ),
                  ],
                ),
              ),
            ),

          // Message Bubbles Feed
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.whatsappGreen))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_outlined, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 10),
                            const Text(
                              'This chat folder is empty',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Send a note or attach files below.',
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final item = _messages[i];
                          return FileBubble(item: item, isOutgoing: true);
                        },
                      ),
          ),

          // Sending Indicator
          if (_isSending)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: AppTheme.darkSurface,
              child: Row(
                children: const [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.whatsappGreen),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Saving directly to your Google Drive...',
                    style: TextStyle(fontSize: 12, color: AppTheme.whatsappGreen),
                  ),
                ],
              ),
            ),

          // Bottom Chat Input Bar (WhatsApp style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.darkSurface,
              border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 0.8)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppTheme.textSecondary),
                    onPressed: _handlePickAndUploadFile,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardElevated,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        onSubmitted: (_) => _handleSendText(),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Type a note or memo...',
                          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor: AppTheme.whatsappGreen,
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                      onPressed: _handleSendText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
