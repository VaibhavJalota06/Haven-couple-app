import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/game_models.dart';

class WouldYouRatherGameScreen extends StatefulWidget {
  const WouldYouRatherGameScreen({super.key});

  @override
  State<WouldYouRatherGameScreen> createState() => _WouldYouRatherGameScreenState();
}

class _WouldYouRatherGameScreenState extends State<WouldYouRatherGameScreen> {
  int _currentIndex = 0;
  String? _selectedOption; // 'A' or 'B'
  final List<WouldYouRatherQuestion> _questions = WouldYouRatherQuestion.defaultQuestions;

  void _chooseOption(String option) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedOption = option;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You finished all questions! Great conversations! 🎉'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQ = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${_questions.length}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Text(
                'Would You Rather...',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: isDark ? AppColors.champagne : AppColors.champagneDark,
                    ),
              ),
              const SizedBox(height: 24),

              // Option A Card
              Expanded(
                child: _buildChoiceCard(
                  title: 'OPTION A',
                  content: currentQ.optionA,
                  isSelected: _selectedOption == 'A',
                  color: AppColors.champagne,
                  onTap: () => _chooseOption('A'),
                ),
              ),

              const SizedBox(height: 16),

              // Center VS Divider Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: const Text(
                  'OR',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Option B Card
              Expanded(
                child: _buildChoiceCard(
                  title: 'OPTION B',
                  content: currentQ.optionB,
                  isSelected: _selectedOption == 'B',
                  color: AppColors.roseDust,
                  onTap: () => _chooseOption('B'),
                ),
              ),

              const SizedBox(height: 24),

              if (_selectedOption != null)
                CustomButton(
                  text: _currentIndex < _questions.length - 1 ? 'Next Question' : 'Finish Game',
                  onPressed: _nextQuestion,
                  variant: ButtonVariant.primary,
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String content,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: color,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
