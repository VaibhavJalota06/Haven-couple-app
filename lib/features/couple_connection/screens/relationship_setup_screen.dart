import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../navigation/main_navigation_screen.dart';
import '../bloc/couple_bloc.dart';
import '../bloc/couple_event.dart';
import '../models/relationship_model.dart';

class RelationshipSetupScreen extends StatefulWidget {
  final RelationshipModel relationship;

  const RelationshipSetupScreen({super.key, required this.relationship});

  @override
  State<RelationshipSetupScreen> createState() => _RelationshipSetupScreenState();
}

class _RelationshipSetupScreenState extends State<RelationshipSetupScreen> {
  final _nicknameController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.relationship.anniversaryDate ?? DateTime.now();
    _nicknameController.text = widget.relationship.customNickname ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.champagne,
              onPrimary: AppColors.darkBackground,
              surface: AppColors.darkSurfaceElevated,
              onSurface: AppColors.textPrimaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveAndProceed() {
    context.read<CoupleBloc>().add(
          UpdateRelationshipDetailsRequested(
            relationshipId: widget.relationship.id,
            anniversaryDate: _selectedDate,
            customNickname: _nicknameController.text.trim().isNotEmpty
                ? _nicknameController.text.trim()
                : null,
          ),
        );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Center(
                    child: Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Connected!',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Let’s personalize your private digital home.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 36),

              // Anniversary / Relationship Start Date Picker
              Text(
                'When did your journey begin?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.champagne),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate != null
                                ? DateFormat('MMMM d, yyyy').format(_selectedDate!)
                                : 'Select Anniversary Date',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiaryDark),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              CustomTextField(
                controller: _nicknameController,
                hintText: 'e.g. Maya & Liam, The Duo',
                labelText: 'Couple Nickname (Optional)',
                prefixIcon: Icons.edit_note_rounded,
              ),

              const SizedBox(height: 48),

              CustomButton(
                text: 'Enter Haven',
                onPressed: _saveAndProceed,
                variant: ButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
