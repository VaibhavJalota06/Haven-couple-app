import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/love_note_model.dart';
import '../repositories/love_notes_repository.dart';

class LoveNotesCapsuleScreen extends StatefulWidget {
  final String relationshipId;
  final String partnerName;

  const LoveNotesCapsuleScreen({
    super.key,
    required this.relationshipId,
    required this.partnerName,
  });

  @override
  State<LoveNotesCapsuleScreen> createState() => _LoveNotesCapsuleScreenState();
}

class _LoveNotesCapsuleScreenState extends State<LoveNotesCapsuleScreen> {
  final _repository = LoveNotesRepository();

  void _showWriteNoteModal() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    DateTime unlockDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.mark_email_unread_rounded, color: AppColors.roseDust, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Write Time Capsule Letter for ${widget.partnerName}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Title / Occasion',
                        hintText: 'e.g. Open on our 1st Anniversary 🥂',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Your Love Letter',
                        hintText: 'Write something heartfelt to surprise them in the future...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                      leading: const Icon(Icons.lock_clock_rounded, color: AppColors.champagne),
                      title: const Text('Unlock Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(unlockDate), style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: unlockDate,
                          firstDate: DateTime.now().add(const Duration(hours: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setModalState(() => unlockDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    CustomButton(
                      text: 'Seal & Lock Capsule 💌🔒',
                      variant: ButtonVariant.primary,
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill out the title and letter content.')),
                          );
                          return;
                        }
                        await _repository.createLoveNote(
                          relationshipId: widget.relationshipId,
                          title: titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          unlockAt: unlockDate,
                        );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Time Capsule sealed! Unlocks on ${DateFormat('MMM d, yyyy').format(unlockDate)} ✨')),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openNote(LoveNoteModel note) {
    if (!note.isUnlocked) {
      final days = note.unlockAt.difference(DateTime.now()).inDays + 1;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.lock_rounded, color: AppColors.champagne),
              SizedBox(width: 8),
              Text('Capsule Locked 🔒'),
            ],
          ),
          content: Text(
            'This letter was sealed with love by your partner and will automatically unlock in $days days on ${DateFormat('MMMM d, yyyy').format(note.unlockAt)}.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Can\'t wait! ✨'),
            ),
          ],
        ),
      );
      return;
    }

    _repository.markAsRead(note.id);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sealed on ${DateFormat('MMMM d, yyyy').format(note.createdAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 14),
              Text(
                note.content,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.champagne, foregroundColor: Colors.black),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close ❤️'),
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
        title: const Text('Time Capsule Love Letters 💌'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.champagne,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Seal New Letter', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showWriteNoteModal,
      ),
      body: StreamBuilder<List<LoveNoteModel>>(
        stream: _repository.getLoveNotesStream(widget.relationshipId),
        builder: (context, snapshot) {
          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.roseDust.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mail_lock_rounded, size: 64, color: AppColors.roseDust),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Sealed Love Letters Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Write a surprise letter for ${widget.partnerName} and set a future date when it unlocks!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final note = notes[index];
              final isUnlocked = note.isUnlocked;

              return GlassCard(
                onTap: () => _openNote(note),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUnlocked ? AppColors.champagne.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUnlocked ? Icons.drafts_rounded : Icons.lock_clock_rounded,
                      color: isUnlocked ? AppColors.champagne : Colors.grey,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    isUnlocked
                        ? 'Unlocked on ${DateFormat('MMM d, yyyy').format(note.unlockAt)} • Tap to read'
                        : 'Locked until ${DateFormat('MMM d, yyyy').format(note.unlockAt)} 🔒',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnlocked ? AppColors.champagneDark : Colors.grey,
                      fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
