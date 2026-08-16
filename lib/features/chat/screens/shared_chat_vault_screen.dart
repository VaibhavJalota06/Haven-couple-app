import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../vault/models/vault_item_model.dart';

class SharedChatVaultScreen extends StatefulWidget {
  final String partnerName;
  final String conversationId;

  const SharedChatVaultScreen({
    super.key,
    required this.partnerName,
    required this.conversationId,
  });

  @override
  State<SharedChatVaultScreen> createState() => _SharedChatVaultScreenState();
}

class _SharedChatVaultScreenState extends State<SharedChatVaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUnlocked = false;
  String _pin = '';
  final String _correctSharedPin = '1234'; // Default shared PIN
  String? _errorMessage;

  final List<VaultItemModel> _vaultItems = [
    VaultItemModel(
      id: 'note_shared_1',
      relationshipId: 'rel_shared',
      ownerId: 'usr_me',
      title: 'Our Secret Trip Itinerary ✈️',
      encryptedPayload: 'Surprise sunset dinner booked at Cliff House for 7:30 PM. Don\'t tell anyone yet!',
      iv: 'iv_mock_1',
      authTag: 'tag_mock_1',
      itemType: VaultItemType.note,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    VaultItemModel(
      id: 'photo_shared_1',
      relationshipId: 'rel_shared',
      ownerId: 'usr_me',
      title: 'First Sunset Together',
      encryptedPayload: 'enc_photo_data',
      iv: 'iv_mock_2',
      authTag: 'tag_mock_2',
      mediaUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&q=80',
      itemType: VaultItemType.photo,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    VaultItemModel(
      id: 'memo_shared_1',
      relationshipId: 'rel_shared',
      ownerId: 'usr_me',
      title: 'Midnight Voice Note 🌙',
      encryptedPayload: 'enc_voice_data',
      iv: 'iv_mock_3',
      authTag: 'tag_mock_3',
      mediaUrl: 'https://example.com/audio/secret_memo.aac',
      itemType: VaultItemType.voiceMemo,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onKeypadTap(String value) {
    if (_pin.length < 4) {
      setState(() {
        _pin += value;
        _errorMessage = null;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _verifyPin() {
    if (_pin == _correctSharedPin) {
      setState(() {
        _isUnlocked = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = 'Incorrect shared PIN. Try 1234 or ask ${widget.partnerName}';
        _pin = '';
      });
    }
  }

  void _addItemDialog(VaultItemType type) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Shared ${type == VaultItemType.note ? "Secret Note" : "Photo / Memory"}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            if (type == VaultItemType.note)
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Encrypted content (only both of you can read)',
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              )
            else
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, size: 32, color: AppColors.champagne),
                      SizedBox(height: 6),
                      Text('Photo selected from camera/gallery', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.champagne),
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    setState(() {
                      _vaultItems.insert(
                        0,
                        VaultItemModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          relationshipId: widget.conversationId,
                          ownerId: 'usr_me',
                          title: titleController.text.trim(),
                          encryptedPayload: contentController.text.trim(),
                          iv: 'iv_dyn',
                          authTag: 'tag_dyn',
                          itemType: type,
                          mediaUrl: type == VaultItemType.photo
                              ? 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80'
                              : null,
                          createdAt: DateTime.now(),
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save to Shared Vault', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isUnlocked) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.partnerName} & You'),
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_rounded, size: 64, color: AppColors.champagne),
              const SizedBox(height: 16),
              Text(
                'Shared Secret Vault',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'End-to-end encrypted space shared exclusively with ${widget.partnerName}. Enter your shared 4-digit PIN.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.champagne : Colors.transparent,
                      border: Border.all(color: AppColors.champagne, width: 2),
                    ),
                  );
                }),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
              const Spacer(),
              // Keypad
              _buildKeypad(isDark),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    final notes = _vaultItems.where((i) => i.itemType == VaultItemType.note).toList();
    final photos = _vaultItems.where((i) => i.itemType == VaultItemType.photo).toList();
    final memos = _vaultItems.where((i) => i.itemType == VaultItemType.voiceMemo).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.partnerName}\'s Shared Vault 🔒'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded),
            tooltip: 'Lock Vault',
            onPressed: () => setState(() {
              _isUnlocked = false;
              _pin = '';
            }),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.champagne,
          dividerColor: Colors.transparent,
          dividerHeight: 0,
          labelColor: isDark ? AppColors.champagne : AppColors.champagneDark,
          unselectedLabelColor: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          tabs: const [
            Tab(text: 'Notes'),
            Tab(text: 'Photos'),
            Tab(text: 'Voice'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Notes Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (ctx, i) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.champagne.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, color: AppColors.champagne, size: 20),
                ),
                title: Text(notes[i].title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    notes[i].encryptedPayload,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          // Photos Tab
          GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: photos.length,
            itemBuilder: (ctx, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(photos[i].mediaUrl ?? '', fit: BoxFit.cover),
            ),
          ),
          // Voice Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memos.length,
            itemBuilder: (ctx, i) => Card(
              child: ListTile(
                leading: const Icon(Icons.mic_rounded, color: AppColors.roseDust),
                title: Text(memos[i].title),
                subtitle: const Text('Voice note • Tap to play'),
                trailing: const Icon(Icons.play_circle_filled_rounded, color: AppColors.champagne, size: 32),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playing secret voice memo... 🎵')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.champagne,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
        onPressed: () {
          final index = _tabController.index;
          final type = index == 0
              ? VaultItemType.note
              : (index == 1 ? VaultItemType.photo : VaultItemType.voiceMemo);
          _addItemDialog(type);
        },
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'back'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 72, height: 72);
                }
                if (key == 'back') {
                  return InkWell(
                    onTap: _onBackspace,
                    borderRadius: BorderRadius.circular(36),
                    child: const SizedBox(
                      width: 72,
                      height: 72,
                      child: Center(child: Icon(Icons.backspace_outlined, size: 24)),
                    ),
                  );
                }
                return InkWell(
                  onTap: () => _onKeypadTap(key),
                  borderRadius: BorderRadius.circular(36),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Text(
                        key,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
