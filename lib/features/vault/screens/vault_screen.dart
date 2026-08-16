import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../couple_connection/bloc/couple_bloc.dart';
import '../../couple_connection/bloc/couple_state.dart';
import '../models/vault_item_model.dart';
import '../repositories/vault_repository.dart';
import '../widgets/add_vault_item_modal.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with SingleTickerProviderStateMixin {
  final _biometricService = BiometricService();
  final _vaultRepository = VaultRepository();
  bool _isUnlocked = false;
  bool _isLoading = false;
  List<VaultItemModel> _vaultItems = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _promptBiometrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _promptBiometrics() async {
    setState(() => _isLoading = true);
    final authenticated = await _biometricService.authenticate(
      reason: 'Unlock your private Vault containing encrypted memories and notes',
    );
    if (authenticated && mounted) {
      setState(() {
        _isUnlocked = true;
        _isLoading = false;
      });
      _loadVaultItems();
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVaultItems() async {
    final coupleState = context.read<CoupleBloc>().state;
    if (coupleState is CouplePaired) {
      final items = await _vaultRepository.getVaultItems(coupleState.relationship.id);
      if (mounted) {
        setState(() {
          _vaultItems = items;
        });
      }
    }
  }

  void _showAddItemModal() {
    final coupleState = context.read<CoupleBloc>().state;
    if (coupleState is CouplePaired) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddVaultItemModal(
          relationshipId: coupleState.relationship.id,
          onItemAdded: _loadVaultItems,
        ),
      );
    }
  }

  void _showItemDetails(VaultItemModel item) async {
    final decrypted = await _vaultRepository.decryptVaultPayload(item);
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.champagne.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'AES-256 Decrypted Payload',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.champagneDark),
              ),
            ),
            const SizedBox(height: 16),
            Text(decrypted, style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isUnlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Private Vault')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    border: Border.all(color: AppColors.champagne),
                  ),
                  child: const Icon(Icons.lock_rounded, size: 36, color: AppColors.champagne),
                ),
                const SizedBox(height: 24),
                Text(
                  'Vault is Locked',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'All items inside are encrypted on-device. Authenticate to unlock.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Unlock with Biometrics',
                  icon: Icons.fingerprint_rounded,
                  onPressed: _promptBiometrics,
                  isLoading: _isLoading,
                  variant: ButtonVariant.primary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final notes = _vaultItems.where((i) => i.itemType == VaultItemType.note).toList();
    final photos = _vaultItems.where((i) => i.itemType == VaultItemType.photo).toList();
    final voiceMemos = _vaultItems.where((i) => i.itemType == VaultItemType.voiceMemo).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Vault'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.champagne,
          dividerColor: Colors.transparent,
          dividerHeight: 0,
          labelColor: isDark ? AppColors.champagne : AppColors.champagneDark,
          unselectedLabelColor: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          tabs: const [
            Tab(text: 'Secret Notes'),
            Tab(text: 'Private Photos'),
            Tab(text: 'Voice Memories'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded),
            tooltip: 'Lock Vault',
            onPressed: () => setState(() => _isUnlocked = false),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Notes Tab
          _buildNotesList(notes, isDark),
          // Photos Tab
          _buildPhotosGrid(photos, isDark),
          // Voice Tab
          _buildVoiceList(voiceMemos, isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemModal,
        backgroundColor: AppColors.champagne,
        foregroundColor: AppColors.darkBackground,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add to Vault', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildNotesList(List<VaultItemModel> notes, bool isDark) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_person_outlined, size: 48, color: isDark ? AppColors.textTertiaryDark : Colors.grey),
            const SizedBox(height: 12),
            const Text('No secret notes saved yet.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => _showItemDetails(note),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.champagne.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.note_alt_outlined, color: AppColors.champagne, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      '🔒 Encrypted with AES-256-GCM',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiaryDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotosGrid(List<VaultItemModel> photos, bool isDark) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: isDark ? AppColors.textTertiaryDark : Colors.grey),
            const SizedBox(height: 12),
            const Text('No encrypted photos in vault.'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return InkWell(
          onTap: () => _showItemDetails(photo),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.champagne.withOpacity(0.3)),
            ),
            child: const Center(
              child: Icon(Icons.lock_rounded, color: AppColors.champagne),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceList(List<VaultItemModel> voiceMemos, bool isDark) {
    if (voiceMemos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none_outlined, size: 48, color: isDark ? AppColors.textTertiaryDark : Colors.grey),
            const SizedBox(height: 12),
            const Text('No private voice memos stored.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: voiceMemos.length,
      itemBuilder: (context, index) {
        final memo = voiceMemos[index];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => _showItemDetails(memo),
          child: Row(
            children: [
              const Icon(Icons.play_circle_filled_rounded, color: AppColors.roseDust, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(memo.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Encrypted audio memo', style: TextStyle(fontSize: 12, color: AppColors.textTertiaryDark)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
