import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/drive_item.dart';
import '../services/google_auth_service.dart';
import '../services/google_drive_service.dart';
import '../services/share_intent_service.dart';
import '../theme/app_theme.dart';
import '../widgets/whatsapp_doodle_background.dart';
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
  String _selectedFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadChats();

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

  List<DriveItem> get _filteredChats {
    if (_selectedFilter == 'All') return _chats;
    if (_selectedFilter == 'Photos') {
      return _chats.where((c) => c.name.toLowerCase().contains('photo') || c.name.toLowerCase().contains('image') || c.name.toLowerCase().contains('camera')).toList();
    }
    if (_selectedFilter == 'Documents') {
      return _chats.where((c) => !c.name.toLowerCase().contains('photo')).toList();
    }
    return _chats;
  }

  void _showNewChatDialog() {
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
            Icon(Icons.create_new_folder_rounded, color: AppTheme.whatsappGreen),
            SizedBox(width: 10),
            Text('New Folder Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a folder name. It will be created directly in your personal Google Drive:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Medical Bills, Taxes, Home',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppTheme.inputPill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
              backgroundColor: AppTheme.whatsappTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Create Chat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = GoogleAuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.darkCanvas,
      appBar: AppBar(
        backgroundColor: AppTheme.darkAppBar,
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search chats & Drive folders...',
                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  _searchQuery = val;
                  _loadChats();
                },
              )
            : Row(
                children: [
                  const Text(
                    'MemChat',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.whatsappTeal.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.whatsappTeal.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'Drive',
                      style: TextStyle(
                        color: AppTheme.whatsappTeal,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                  _loadChats();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            tooltip: 'Sync Drive',
            onPressed: _loadChats,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
            color: AppTheme.darkAppBar,
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
                  user != null ? 'Signed in: ${user.email}' : 'Status: Offline Demo Mode',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: AppTheme.whatsappTeal,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.chat_rounded, size: 24),
      ),
      body: Column(
        children: [
          // WhatsApp Style Filter Chips
          Container(
            color: AppTheme.darkAppBar,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Documents'),
                const SizedBox(width: 8),
                _buildFilterChip('Photos'),
              ],
            ),
          ),

          // Chat Folders List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.whatsappTeal),
                  )
                : _filteredChats.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadChats,
                        color: AppTheme.whatsappTeal,
                        backgroundColor: AppTheme.darkAppBar,
                        child: ListView.separated(
                          itemCount: _filteredChats.length,
                          separatorBuilder: (ctx, i) => const Divider(
                            height: 1,
                            thickness: 0.6,
                            indent: 76,
                            color: AppTheme.cardBorder,
                          ),
                          itemBuilder: (ctx, i) {
                            final chat = _filteredChats[i];
                            return _buildChatTile(chat, i);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.whatsappTeal.withOpacity(0.2) : AppTheme.cardElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.whatsappTeal : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.whatsappGreen : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(DriveItem chat, int index) {
    final timeStr = DateFormat('MMM d').format(chat.modifiedTime);

    // Dynamic gradient palette for avatars
    final gradients = [
      [const Color(0xFF0F766E), const Color(0xFF047857)],
      [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
      [const Color(0xFF6B21A8), const Color(0xFF9333EA)],
      [const Color(0xFF9A3412), const Color(0xFFEA580C)],
    ];
    final grad = gradients[index % gradients.length];

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(folder: chat),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Folder Avatar with WhatsApp style ring
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: grad,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: grad[0].withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.folder_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Chat Name & Last Message Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          chat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(
                        Icons.done_all_rounded,
                        size: 15,
                        color: AppTheme.whatsappCheckBlue,
                      ),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Folder synced with Google Drive',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return WhatsAppDoodleBackground(
      opacity: 0.05,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.darkAppBar,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Icon(Icons.folder_off_outlined, size: 36, color: AppTheme.whatsappTeal),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Drive Chats Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create your first folder chat or forward any file from WhatsApp to organize it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showNewChatDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Start First Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.whatsappTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
