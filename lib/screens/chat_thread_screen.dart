import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/drive_item.dart';
import '../services/google_drive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/file_bubble.dart';
import '../widgets/whatsapp_doodle_background.dart';

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
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _loadThread();
    _msgCtrl.addListener(() {
      final has = _msgCtrl.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });
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

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkAppBar,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachOption(
                      icon: Icons.insert_drive_file_rounded,
                      label: 'Document',
                      color: const Color(0xFF7F66FF),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null && result.files.single.path != null) {
                          _uploadFilePath(result.files.single.path!);
                        }
                      },
                    ),
                    _buildAttachOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: const Color(0xFFD3396D),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final picker = ImagePicker();
                        final photo = await picker.pickImage(source: ImageSource.camera);
                        if (photo != null) {
                          _uploadFilePath(photo.path, mimeType: 'image/jpeg');
                        }
                      },
                    ),
                    _buildAttachOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFFAC44CF),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final picker = ImagePicker();
                        final img = await picker.pickImage(source: ImageSource.gallery);
                        if (img != null) {
                          _uploadFilePath(img.path, mimeType: 'image/jpeg');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachOption(
                      icon: Icons.headphones_rounded,
                      label: 'Audio Note',
                      color: const Color(0xFFE06D24),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final result = await FilePicker.platform.pickFiles(type: FileType.audio);
                        if (result != null && result.files.single.path != null) {
                          _uploadFilePath(result.files.single.path!, mimeType: 'audio/m4a');
                        }
                      },
                    ),
                    _buildAttachOption(
                      icon: Icons.create_new_folder_rounded,
                      label: 'Sub-Chat',
                      color: AppTheme.whatsappTeal,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showNewSubchatDialog();
                      },
                    ),
                    _buildAttachOption(
                      icon: Icons.note_alt_outlined,
                      label: 'Quick Note',
                      color: const Color(0xFF02967C),
                      onTap: () {
                        Navigator.pop(ctx);
                        // Focus message bar
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.9),
                  color,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
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
        backgroundColor: AppTheme.darkAppBar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Row(
          children: const [
            Icon(Icons.folder_open_rounded, color: AppTheme.whatsappGreen),
            SizedBox(width: 8),
            Text('Create Sub-Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. 2026 Bills, Scans, Receipts',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            filled: true,
            fillColor: AppTheme.inputPill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
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
              backgroundColor: AppTheme.whatsappTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Create Subfolder'),
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
        backgroundColor: AppTheme.darkAppBar,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF047857)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(
                Icons.folder_rounded,
                color: Colors.white,
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
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${_messages.length} files • Google Drive Folder',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            tooltip: 'Refresh Thread',
            onPressed: _loadThread,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: WhatsAppDoodleBackground(
        child: Column(
          children: [
            // Sub-Chats Row (Nested Drive Folders as WhatsApp Sub-Topic Chips)
            if (_subchats.isNotEmpty || !_isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.darkAppBar.withOpacity(0.95),
                  border: const Border(
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
                              size: 15,
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
                        avatar: const Icon(Icons.add_rounded, size: 16, color: AppTheme.whatsappTeal),
                        label: const Text(
                          'New Sub-chat',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.whatsappTeal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppTheme.whatsappTeal),
                        ),
                        onPressed: _showNewSubchatDialog,
                      ),
                    ],
                  ),
                ),
              ),

            // Messages & Files Feed
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.whatsappTeal),
                    )
                  : ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // WhatsApp Style End-to-End Privacy Pill
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.dateChipBackground.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.lock_rounded, size: 13, color: Color(0xFFFFD279)),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '100% Private. Files are stored directly in your Google Drive.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFFFD279),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Date Chip
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.dateChipBackground.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),

                        // File & Message Bubbles
                        ..._messages.map((item) => FileBubble(item: item, isOutgoing: true)),

                        if (_messages.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 80),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'This chat folder is ready',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Send a memo or attach files below.',
                                    style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            // Live Upload Progress Toast
            if (_isSending)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: AppTheme.darkAppBar,
                child: Row(
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.whatsappGreen),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Uploading to your Google Drive folder...',
                      style: TextStyle(fontSize: 12, color: AppTheme.whatsappGreen),
                    ),
                  ],
                ),
              ),

            // Authentic WhatsApp Bottom Chat Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Input Pill
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.inputPill,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.sentiment_satisfied_alt_outlined,
                                color: AppTheme.textSecondary,
                                size: 23,
                              ),
                              onPressed: () {},
                            ),
                            Expanded(
                              child: TextField(
                                controller: _msgCtrl,
                                minLines: 1,
                                maxLines: 4,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Message or note...',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.attach_file_rounded,
                                color: AppTheme.textSecondary,
                                size: 23,
                              ),
                              onPressed: _showAttachmentMenu,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                color: AppTheme.textSecondary,
                                size: 21,
                              ),
                              onPressed: () async {
                                final picker = ImagePicker();
                                final photo = await picker.pickImage(source: ImageSource.camera);
                                if (photo != null) {
                                  _uploadFilePath(photo.path, mimeType: 'image/jpeg');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),

                    // WhatsApp Circular Action Button (Mic or Send)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppTheme.whatsappTeal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _hasText ? Icons.send_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () {
                          if (_hasText) {
                            _handleSendText();
                          } else {
                            // Micro-prompt for voice note
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tap Attachment > Audio Note to upload voice memo.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
