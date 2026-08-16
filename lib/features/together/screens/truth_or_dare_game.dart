import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/game_models.dart';

class TruthOrDareGameScreen extends StatefulWidget {
  const TruthOrDareGameScreen({super.key});

  @override
  State<TruthOrDareGameScreen> createState() => _TruthOrDareGameScreenState();
}

class _TruthOrDareGameScreenState extends State<TruthOrDareGameScreen> {
  int _currentIndex = 0;
  bool _isCardRevealed = false;
  final List<TruthOrDareCard> _cards = TruthOrDareCard.defaultCards;

  void _revealCard() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isCardRevealed = true;
    });
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _isCardRevealed = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completed all cards! Amazing bonding! 💕'),
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
    final currentCard = _cards[_currentIndex];
    final isTruth = currentCard.isTruth;

    return Scaffold(
      appBar: AppBar(
        title: Text('Card ${_currentIndex + 1} of ${_cards.length}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: (isTruth ? AppColors.champagne : AppColors.roseDust).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTruth ? 'TRUTH CARD' : 'DARE CARD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: isTruth ? AppColors.champagneDark : AppColors.warmCopper,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Interactive Card
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: _isCardRevealed ? null : _revealCard,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: _isCardRevealed
                            ? LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF222838), const Color(0xFF161A25)]
                                    : [const Color(0xFFFFFFFF), const Color(0xFFF9F7F4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isCardRevealed ? AppColors.champagne.withOpacity(0.4) : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.champagne.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isCardRevealed) ...[
                            const Icon(Icons.touch_app_rounded, size: 54, color: Colors.white),
                            const SizedBox(height: 20),
                            const Text(
                              'Tap To Reveal',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              isTruth ? Icons.psychology_outlined : Icons.celebration_outlined,
                              size: 48,
                              color: isTruth ? AppColors.champagne : AppColors.roseDust,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              currentCard.content,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              if (_isCardRevealed)
                CustomButton(
                  text: _currentIndex < _cards.length - 1 ? 'Next Card' : 'Finish Game',
                  onPressed: _nextCard,
                  variant: ButtonVariant.primary,
                ).animate().fadeIn().slideY(begin: 0.2, end: 0)
              else
                CustomButton(
                  text: 'Reveal Challenge',
                  onPressed: _revealCard,
                  variant: ButtonVariant.secondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
