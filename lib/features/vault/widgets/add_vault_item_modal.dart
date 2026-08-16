import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../models/vault_item_model.dart';
import '../repositories/vault_repository.dart';

class AddVaultItemModal extends StatefulWidget {
  final String relationshipId;
  final VoidCallback onItemAdded;

  const AddVaultItemModal({
    super.key,
    required this.relationshipId,
    required this.onItemAdded,
  });

  @override
  State<AddVaultItemModal> createState() => _AddVaultItemModalState();
}

class _AddVaultItemModalState extends State<AddVaultItemModal> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _vaultRepository = VaultRepository();
  bool _isLoading = false;
  VaultItemType _selectedType = VaultItemType.note;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and content')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _vaultRepository.createEncryptedVaultItem(
        relationshipId: widget.relationshipId,
        title: title,
        rawContent: content,
        itemType: _selectedType,
      );
      widget.onItemAdded();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'New Encrypted Vault Item',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Item type selector
          Row(
            children: [
              _buildTypeChip(VaultItemType.note, 'Secret Note', Icons.edit_note_rounded),
              const SizedBox(width: 8),
              _buildTypeChip(VaultItemType.photo, 'Private Photo', Icons.photo_camera_back_rounded),
              const SizedBox(width: 8),
              _buildTypeChip(VaultItemType.voiceMemo, 'Voice Memo', Icons.mic_rounded),
            ],
          ),

          const SizedBox(height: 20),

          CustomTextField(
            controller: _titleController,
            hintText: 'e.g. Letter to open on our anniversary',
            labelText: 'Item Title',
          ),

          const SizedBox(height: 16),

          CustomTextField(
            controller: _contentController,
            hintText: 'Type your private note or encrypted secret...',
            labelText: 'Encrypted Content',
            maxLines: 5,
          ),

          const SizedBox(height: 24),

          CustomButton(
            text: 'Encrypt & Save in Vault',
            icon: Icons.lock_outline_rounded,
            onPressed: _saveItem,
            isLoading: _isLoading,
            variant: ButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(VaultItemType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.champagne.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.champagne : AppColors.darkBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.champagne : AppColors.textTertiaryDark),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.champagne : AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
