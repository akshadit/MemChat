import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/drive_item.dart';
import '../services/google_auth_service.dart';
import '../services/google_drive_service.dart';
import '../services/share_intent_service.dart';
import '../theme/app_theme.dart';
import 'chat_thread_screen.dart';
import 'share_destination_modal.dart';
import 'splash_auth_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<DriveItem> _chats = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChats();

    // Listen to incoming shares from WhatsApp / external apps
    ShareIntentService.instance.addListener(_handleIncomingShare);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleIncomingShare();
    });
  }

  @override
  void dispose() {
    ShareIntentService.instance.removeListener(_handleIncomingShare);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleIncomingShare() {
    final payload = ShareIntentService.instance.pendingPayload;
    if (payload != null && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ShareDestinationModal(
          payload: payload,
          chats: _chats,
          onFinished: () {
            ShareIntentService.instance.clearPendingPayload();
            _loadChats();
          },
        ),
      );
    }
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    final results = await GoogleDriveService.instance.fetchChats(
      searchQuery: _searchQuery,
    );
    if (mounted) {
      setState(() {
        _chats = results;
        _isLoading = false;
      });
    }
  }

  void _showNewChatDialog() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Row(
          children: const [
            Icon(Icons.create_new_folder_outlined, color: AppTheme.whatsappGreen),
            SizedBox(width: 10),
            Text('Start New Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Give this chat a name (it creates a folder in your Google Drive):',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Medical Bills, House Renovation',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.cardElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.whatsappGreen),
                ),
              ),
            ),
          ],
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
                final created = await GoogleDriveService.instance.createChatFolder(name);
                if (created != null && mounted) {
                  _loadChats();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatThreadScreen(folder: created),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.whatsappGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create Chat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = GoogleAuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'MemChat',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.whatsappGreen.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.whatsappGreen.withOpacity(0.4)),
              ),
              child: const Text(
                'Drive Chats',
                style: TextStyle(
                  color: AppTheme.whatsappGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Drive',
            onPressed: _loadChats,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppTheme.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            onSelected: (val) async {
              if (val == 'signout') {
                await GoogleAuthService.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SplashAuthScreen()),
                  );
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  user != null ? 'Signed in as ${user.email}' : 'Running in Demo Mode',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewChatDialog,
        backgroundColor: AppTheme.whatsappGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.chat_bubble_rounded),
        label: const Text(
          'New Chat',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                _searchQuery = val;
                _loadChats();
              },
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search chats & Drive folders...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _loadChats();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.darkSurface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppTheme.whatsappGreen),
                ),
              ),
            ),
          ),

          // Chat Items
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.whatsappGreen),
                  )
                : _chats.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadChats,
                        color: AppTheme.whatsappGreen,
                        child: ListView.separated(
                          itemCount: _chats.length,
                          separatorBuilder: (ctx, i) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 74,
                            color: AppTheme.cardBorder,
                          ),
                          itemBuilder: (ctx, i) {
                            final chat = _chats[i];
                            return _buildChatTile(chat);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(DriveItem chat) {
    final timeStr = DateFormat('MMM d').format(chat.modifiedTime);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.cardElevated,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: const Center(
          child: Icon(
            Icons.folder_rounded,
            color: AppTheme.whatsappGreen,
            size: 26,
          ),
        ),
      ),
      title: Text(
        chat.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          'Tap to open folder chat & files',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeStr,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppTheme.textMuted,
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(folder: chat),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_off_outlined, size: 54, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          const Text(
            'No Drive Folders Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "New Chat" below to start your first folder chat.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showNewChatDialog,
            icon: const Icon(Icons.add),
            label: const Text('Start First Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.whatsappGreen,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
