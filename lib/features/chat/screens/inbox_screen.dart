import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../discover/repositories/discover_repository.dart';
import '../../discover/screens/connection_requests_screen.dart';
import '../models/conversation_thread.dart';
import '../repositories/chat_repository.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  List<ConversationThread> _threads = [];
  List<ConversationThread> _filteredThreads = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadThreads() async {
    final threads = await _chatRepository.getConversationThreads();
    if (mounted) {
      setState(() {
        _threads = threads;
        _filteredThreads = threads;
        _isLoading = false;
      });
    }
  }

  void _filterThreads(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredThreads = _threads;
      } else {
        _filteredThreads = _threads
            .where((t) =>
                t.participant.fullName.toLowerCase().contains(query.toLowerCase()) ||
                (t.participant.nickname?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                t.lastMessage.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _openNewChatDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Start a private chat with a connected friend:'),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: DiscoverRepository.demoUsers.length,
                itemBuilder: (_, index) {
                  final user = DiscoverRepository.demoUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null ? Text(user.fullName[0]) : null,
                    ),
                    title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(user.nickname != null ? '@${user.nickname}' : 'Connected'),
                    trailing: const Icon(Icons.send_rounded, color: AppColors.champagne, size: 20),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(targetUser: user),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _myNote;

  void _showSetNoteDialog() {
    final noteController = TextEditingController(text: _myNote ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: const Text('Share a Note', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Followers/connections can see your note for 24 hours. They won\'t get a notification.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLength: 60,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind? (e.g. 🎧, ☕)',
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.champagne),
            onPressed: () {
              setState(() {
                _myNote = noteController.text.trim().isNotEmpty ? noteController.text.trim() : null;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Share', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'vaibhav_jalota',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 28),
            tooltip: 'New Message',
            onPressed: _openNewChatDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: HavenLoadingIndicator())
          : CustomScrollView(
              slivers: [
                // 1. Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _filterThreads,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Search messages...',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _filterThreads('');
                              },
                              child: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Instagram Notes Tray (Horizontal Avatar Bubbles with Floating Note)
                if (_searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildNotesTray(isDark),
                  ),

                // 3. Messages Header Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Messages',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ConnectionRequestsScreen()),
                            );
                          },
                          child: const Text(
                            'Sparks 💖',
                            style: TextStyle(color: AppColors.champagneDark, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Conversation Threads List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final thread = _filteredThreads[index];
                      return _buildThreadTile(thread, isDark);
                    },
                    childCount: _filteredThreads.length,
                  ),
                ),
              ],
            ),
    );
  }

  // Instagram Notes Tray
  Widget _buildNotesTray(bool isDark) {
    return Container(
      height: 120,
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _threads.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Your Note"
            return GestureDetector(
              onTap: _showSetNoteDialog,
              child: SizedBox(
                width: 76,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Floating Note Bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _myNote != null ? AppColors.champagne : (isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _myNote ?? 'Your note',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: _myNote != null ? FontWeight.bold : FontWeight.normal,
                          color: _myNote != null ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade300,
                          child: const Icon(Icons.person, color: Colors.grey, size: 24),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.champagne,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 12, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Your Note', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }

          final thread = _threads[index - 1];
          final note = thread.activeNote;
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChatScreen(targetUser: thread.participant)),
              );
            },
            child: SizedBox(
              width: 76,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating Note Bubble
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: thread.isSpecialCouple
                            ? AppColors.champagne
                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      note ?? 'Active',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 5),
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: thread.participant.avatarUrl != null
                        ? NetworkImage(thread.participant.avatarUrl!)
                        : null,
                    child: thread.participant.avatarUrl == null ? Text(thread.participant.fullName[0]) : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    thread.participant.nickname ?? thread.participant.fullName.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Conversation Thread List Item
  Widget _buildThreadTile(ConversationThread thread, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(targetUser: thread.participant),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // User Avatar with Online Dot
            Stack(
              children: [
                Container(
                  padding: thread.isSpecialCouple ? const EdgeInsets.all(2) : EdgeInsets.zero,
                  decoration: thread.isSpecialCouple
                      ? const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [AppColors.champagne, AppColors.roseDust]),
                        )
                      : null,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundImage: thread.participant.avatarUrl != null
                        ? NetworkImage(thread.participant.avatarUrl!)
                        : null,
                    child: thread.participant.avatarUrl == null ? Text(thread.participant.fullName[0]) : null,
                  ),
                ),
                if (thread.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkBackground : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // Name & Last Message Preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        thread.participant.fullName,
                        style: TextStyle(
                          fontWeight: thread.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (thread.isSpecialCouple) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.favorite_rounded, color: AppColors.roseDust, size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    thread.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: thread.unreadCount > 0 ? FontWeight.w700 : FontWeight.normal,
                      color: thread.unreadCount > 0
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Timestamp & Camera Quick Reply Icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateTime.now().difference(thread.lastMessageTime).inMinutes < 60
                      ? '${DateTime.now().difference(thread.lastMessageTime).inMinutes}m'
                      : '${DateTime.now().difference(thread.lastMessageTime).inHours}h',
                  style: TextStyle(
                    fontSize: 11,
                    color: thread.unreadCount > 0
                        ? AppColors.champagneDark
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    fontWeight: thread.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 6),
                if (thread.unreadCount > 0)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.champagne,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Send quick photo reply to ${thread.participant.fullName}! 📸')),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
