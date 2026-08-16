import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../models/mood_model.dart';

class MoodSelectorModal extends StatefulWidget {
  final String currentMood;

  const MoodSelectorModal({super.key, required this.currentMood});

  @override
  State<MoodSelectorModal> createState() => _MoodSelectorModalState();
}

class _MoodSelectorModalState extends State<MoodSelectorModal> {
  late String _selectedMoodId;
  String _selectedEmoji = '🥰';

  @override
  void initState() {
    super.initState();
    _selectedMoodId = widget.currentMood;
  }

  void _saveMood() {
    context.read<AuthBloc>().add(
          AuthProfileUpdateRequested(
            mood: _selectedMoodId,
            moodEmoji: _selectedEmoji,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
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
          const SizedBox(height: 20),
          Text(
            'How are you feeling?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Let your partner know your current vibe.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),

          // Mood Grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MoodModel.presetMoods.map((mood) {
              final isSelected = _selectedMoodId == mood.id;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedMoodId = mood.id;
                    _selectedEmoji = mood.emoji;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppColors.champagne.withOpacity(0.18) : AppColors.champagneLight)
                        : (isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? AppColors.champagne : AppColors.champagneDark)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? (isDark ? AppColors.champagne : AppColors.champagneDark)
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          CustomButton(
            text: 'Update Mood',
            onPressed: _saveMood,
            variant: ButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}
