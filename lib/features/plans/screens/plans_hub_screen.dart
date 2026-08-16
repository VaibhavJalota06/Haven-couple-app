import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../couple_connection/bloc/couple_bloc.dart';
import '../../couple_connection/bloc/couple_state.dart';
import '../models/plan_models.dart';
import '../repositories/plans_repository.dart';

class PlansHubScreen extends StatefulWidget {
  const PlansHubScreen({super.key});

  @override
  State<PlansHubScreen> createState() => _PlansHubScreenState();
}

class _PlansHubScreenState extends State<PlansHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _plansRepository = PlansRepository();

  String _dateCategoryFilter = 'All';
  String _bucketCategoryFilter = 'All';

  // Date ideas pool for "Roll Date Idea 🎲"
  final List<Map<String, String>> _dateIdeas = [
    {
      'title': 'Stargazing Picnic with Hot Cocoa ☕✨',
      'category': 'Outdoor',
      'location': 'Hilltop Observatory Viewpoint',
      'budget': '25',
    },
    {
      'title': 'Couples Clay Pottery Masterclass 🏺',
      'category': 'Workshop',
      'budget': '40',
    },
    {
      'title': 'Gourmet French Baking Bake-off at Home 🥐',
      'category': 'Surprise',
      'location': 'Our Kitchen',
      'budget': '30',
    },
    {
      'title': 'Private Sunrise Kayaking & Breakfast 🛶🥐',
      'category': 'Trip',
      'location': 'Emerald Lake Marina',
      'budget': '60',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // CURRENCY PICKER MODAL
  // ==========================================
  void _showCurrencyPickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final currencies = CurrencyService.allCurrencies;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          height: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Currency & Region',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.champagne.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Auto: ${CurrencyService.flag} ${CurrencyService.code}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.champagne),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Auto-detected: ${CurrencyService.name} (${CurrencyService.symbol})',
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: currencies.length,
                  itemBuilder: (context, idx) {
                    final c = currencies[idx];
                    final isSelected = c.code == CurrencyService.code;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                      title: Text('${c.code} (${c.symbol})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(c.name, style: const TextStyle(fontSize: 12)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.champagne)
                          : null,
                      onTap: () {
                        CurrencyService.setCurrency(c);
                        Navigator.of(ctx).pop();
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Currency switched to ${c.flag} ${c.code} (${c.symbol})'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // RANDOM DATE IDEA GENERATOR
  // ==========================================
  void _rollRandomDateIdea(String relationshipId) {
    final random = Random();
    final idea = _dateIdeas[random.nextInt(_dateIdeas.length)];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.champagne.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🎲', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                const Text('Spontaneous Date Idea!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              idea['title']!,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.champagneDark),
                const SizedBox(width: 4),
                Text(idea['location']!, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                const SizedBox(width: 12),
                const Icon(Icons.attach_money_rounded, size: 16, color: Colors.green),
                Text('${CurrencyService.symbol}${idea['budget']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _rollRandomDateIdea(relationshipId);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Roll Another 🎲'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Add to Plans ✨',
                    onPressed: () async {
                      await _plansRepository.createDatePlan(
                        relationshipId: relationshipId,
                        title: idea['title']!,
                        locationName: idea['location'],
                        budget: double.tryParse(idea['budget']!) ?? 0,
                        category: idea['category']!,
                        scheduledFor: DateTime.now().add(const Duration(days: 3, hours: 4)),
                      );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✨ "${idea['title']}" added to your Date Planner!'),
                            backgroundColor: AppColors.champagneDark,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ADD MODALS
  // ==========================================
  void _showAddPlanModal(String relationshipId) {
    final currentTab = _tabController.index;
    if (currentTab == 0) {
      _showAddDateModal(relationshipId);
    } else if (currentTab == 1) {
      _showAddBucketItemModal(relationshipId);
    } else {
      _showAddGoalModal(relationshipId);
    }
  }

  void _showAddDateModal(String relationshipId, {DatePlanModel? editPlan}) {
    final titleController = TextEditingController(text: editPlan?.title ?? '');
    final locationController = TextEditingController(text: editPlan?.locationName ?? '');
    final descController = TextEditingController(text: editPlan?.description ?? '');
    final budgetController = TextEditingController(text: editPlan != null && editPlan.budget > 0 ? editPlan.budget.toStringAsFixed(0) : '');
    DateTime selectedDate = editPlan?.scheduledFor ?? DateTime.now().add(const Duration(days: 3, hours: 2));
    String selectedCategory = editPlan?.category ?? 'Dinner';

    final categories = ['Dinner', 'Cinema', 'Outdoor', 'Workshop', 'Trip', 'Surprise', 'Spa'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    editPlan != null ? 'Edit Date Plan' : 'Plan a New Date 💕',
                    style: Theme.of(modalCtx).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: titleController,
                    hintText: 'e.g. Candlelight Italian Dinner & Drinks',
                    labelText: 'Date Idea *',
                  ),
                  const SizedBox(height: 14),
                  // Category chips
                  const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.champagne,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setModalState(() => selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // Date & Time picker tile
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_rounded, color: AppColors.champagneDark),
                    title: Text(
                      DateFormat('EEE, MMM d, yyyy • h:mm a').format(selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('Tap to change date & time', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: modalCtx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (pickedDate != null && modalCtx.mounted) {
                        final pickedTime = await showTimePicker(
                          context: modalCtx,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (pickedTime != null) {
                          setModalState(() {
                            selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(controller: locationController, hintText: 'e.g. Trattoria Bella Rooftop', labelText: 'Location Name'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: budgetController,
                          hintText: 'e.g. 100',
                          labelText: 'Est. Budget (${CurrencyService.symbol})',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: descController,
                          hintText: 'Optional notes / dress code',
                          labelText: 'Notes',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: editPlan != null ? 'Update Date Plan' : 'Save Date Plan',
                    onPressed: () async {
                      if (titleController.text.trim().isNotEmpty) {
                        final budget = double.tryParse(budgetController.text.trim()) ?? 0.0;
                        if (editPlan != null) {
                          await _plansRepository.updateDatePlan(
                            editPlan.copyWith(
                              title: titleController.text.trim(),
                              locationName: locationController.text.trim(),
                              description: descController.text.trim(),
                              budget: budget,
                              category: selectedCategory,
                              scheduledFor: selectedDate,
                            ),
                          );
                        } else {
                          await _plansRepository.createDatePlan(
                            relationshipId: relationshipId,
                            title: titleController.text.trim(),
                            locationName: locationController.text.trim(),
                            description: descController.text.trim(),
                            budget: budget,
                            category: selectedCategory,
                            scheduledFor: selectedDate,
                          );
                        }
                        if (modalCtx.mounted) Navigator.of(modalCtx).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddBucketItemModal(String relationshipId, {BucketListItemModel? editItem}) {
    final titleController = TextEditingController(text: editItem?.title ?? '');
    final descController = TextEditingController(text: editItem?.description ?? '');
    String selectedCategory = editItem?.category ?? 'Travel';
    DateTime? selectedTargetDate = editItem?.targetDate;

    final categories = ['Travel', 'Adventure', 'Experience', 'Milestone', 'Life', 'Learning'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    editItem != null ? 'Edit Bucket Wish' : 'Add Bucket List Wish ✨',
                    style: Theme.of(modalCtx).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: titleController,
                    hintText: 'e.g. Hot air balloon ride in Cappadocia',
                    labelText: 'Dream / Wish *',
                  ),
                  const SizedBox(height: 14),
                  const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.champagne,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setModalState(() => selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_rounded, color: AppColors.champagneDark),
                    title: Text(
                      selectedTargetDate != null ? DateFormat('MMMM yyyy').format(selectedTargetDate!) : 'Target Date (Optional)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('Set an ideal timeframe to achieve this', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: modalCtx,
                        initialDate: selectedTargetDate ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedTargetDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: descController,
                    hintText: 'Why this matters to both of you, steps to get there...',
                    labelText: 'Details & Inspiration',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: editItem != null ? 'Update Wish' : 'Add to Bucket List',
                    onPressed: () async {
                      if (titleController.text.trim().isNotEmpty) {
                        if (editItem != null) {
                          await _plansRepository.updateBucketListItem(
                            editItem.copyWith(
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              category: selectedCategory,
                              targetDate: selectedTargetDate,
                            ),
                          );
                        } else {
                          await _plansRepository.createBucketListItem(
                            relationshipId: relationshipId,
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            category: selectedCategory,
                            targetDate: selectedTargetDate,
                          );
                        }
                        if (modalCtx.mounted) Navigator.of(modalCtx).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddGoalModal(String relationshipId, {SharedGoalModel? editGoal}) {
    final titleController = TextEditingController(text: editGoal?.title ?? '');
    final targetAmountController = TextEditingController(text: editGoal != null ? editGoal.targetAmount.toStringAsFixed(0) : '');
    final currentAmountController = TextEditingController(text: editGoal != null ? editGoal.currentAmount.toStringAsFixed(0) : '0');
    String selectedCategory = editGoal?.category ?? 'Travel';
    DateTime? selectedTargetDate = editGoal?.targetDate;

    final categories = ['Travel', 'Home', 'Celebration', 'Finance', 'Wedding', 'Future'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    editGoal != null ? 'Edit Shared Goal' : 'New Shared Goal 🎯',
                    style: Theme.of(modalCtx).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: titleController,
                    hintText: 'e.g. Dream Japan Trip Fund ✈️',
                    labelText: 'Goal Title *',
                  ),
                  const SizedBox(height: 14),
                  const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.champagne,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setModalState(() => selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: targetAmountController,
                          hintText: '5000',
                          labelText: 'Target Amount (${CurrencyService.symbol})',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: currentAmountController,
                          hintText: '0',
                          labelText: 'Current Saved (${CurrencyService.symbol})',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_rounded, color: AppColors.champagneDark),
                    title: Text(
                      selectedTargetDate != null ? DateFormat('MMMM yyyy').format(selectedTargetDate!) : 'Target Completion Date (Optional)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text('Target completion timeframe', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: modalCtx,
                        initialDate: selectedTargetDate ?? DateTime.now().add(const Duration(days: 180)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedTargetDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: editGoal != null ? 'Update Goal' : 'Create Shared Goal',
                    onPressed: () async {
                      final target = double.tryParse(targetAmountController.text.trim()) ?? 1000.0;
                      final current = double.tryParse(currentAmountController.text.trim()) ?? 0.0;

                      if (titleController.text.trim().isNotEmpty) {
                        if (editGoal != null) {
                          await _plansRepository.updateSharedGoal(
                            editGoal.copyWith(
                              title: titleController.text.trim(),
                              targetAmount: target,
                              currentAmount: current,
                              category: selectedCategory,
                              targetDate: selectedTargetDate,
                              isCompleted: current >= target,
                            ),
                          );
                        } else {
                          await _plansRepository.createSharedGoal(
                            relationshipId: relationshipId,
                            title: titleController.text.trim(),
                            targetAmount: target,
                            currentAmount: current,
                            category: selectedCategory,
                            targetDate: selectedTargetDate,
                          );
                        }
                        if (modalCtx.mounted) Navigator.of(modalCtx).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // QUICK GOAL CONTRIBUTION MODAL
  // ==========================================
  void _showContributeModal(SharedGoalModel goal) {
    final customAmountController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Contribute to Goal 💰', style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              goal.title,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.champagneDark),
            ),
            const SizedBox(height: 16),
            const Text('Quick Add Amount:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [20, 50, 100, 250].map((amount) {
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.champagne),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () async {
                    await _plansRepository.addGoalContribution(goal.id, amount.toDouble());
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🎉 Added ${CurrencyService.symbol}$amount to "${goal.title}"!'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    }
                  },
                  child: Text('+${CurrencyService.symbol}$amount', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: customAmountController,
              hintText: 'Enter custom amount (e.g. 75)',
              labelText: 'Custom Amount (${CurrencyService.symbol})',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Add Contribution',
              onPressed: () async {
                final val = double.tryParse(customAmountController.text.trim());
                if (val != null && val > 0) {
                  await _plansRepository.addGoalContribution(goal.id, val);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 Added ${CurrencyService.symbol}$val to "${goal.title}"!'),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BUILD SCREEN
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CoupleBloc, CoupleState>(
      builder: (context, coupleState) {
        final relationship = (coupleState is CouplePaired) ? coupleState.relationship : null;

        if (relationship == null) {
          return const Scaffold(
            body: HavenLoadingIndicator(message: 'Loading plans & goals...'),
          );
        }

        return ListenableBuilder(
          listenable: CurrencyService.notifier,
          builder: (context, _) {
            return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.champagne.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars_rounded, color: AppColors.champagneDark, size: 18),
                ),
                const SizedBox(width: 8),
                const Text('Plans & Goals', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              InkWell(
                onTap: _showCurrencyPickerSheet,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.champagne.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(CurrencyService.flag, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${CurrencyService.code} (${CurrencyService.symbol})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.champagne),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (_tabController.index == 0)
                IconButton(
                  icon: const Icon(Icons.casino_outlined, size: 22),
                  tooltip: 'Roll Date Idea 🎲',
                  onPressed: () => _rollRandomDateIdea(relationship.id),
                )
              else if (_tabController.index == 1)
                IconButton(
                  icon: const Icon(Icons.auto_awesome_outlined, size: 22),
                  tooltip: 'Add Bucket Wish ✨',
                  onPressed: () => _showAddBucketItemModal(relationship.id),
                )
              else
                IconButton(
                  icon: const Icon(Icons.add_card_rounded, size: 22),
                  tooltip: 'New Savings Goal 💰',
                  onPressed: () => _showAddGoalModal(relationship.id),
                ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.champagne,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              labelColor: isDark ? AppColors.champagne : AppColors.champagneDark,
              unselectedLabelColor: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              tabs: const [
                Tab(icon: Icon(Icons.event_rounded, size: 18), text: 'Date Planner'),
                Tab(icon: Icon(Icons.checklist_rounded, size: 18), text: 'Bucket List'),
                Tab(icon: Icon(Icons.savings_rounded, size: 18), text: 'Shared Goals'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDatePlansTab(relationship.id, isDark),
              _buildBucketListTab(relationship.id, isDark),
              _buildGoalsTab(relationship.id, isDark),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddPlanModal(relationship.id),
            backgroundColor: AppColors.champagne,
            foregroundColor: AppColors.darkBackground,
            icon: Icon(
              _tabController.index == 0
                  ? Icons.event_available_rounded
                  : (_tabController.index == 1 ? Icons.star_rounded : Icons.savings_rounded),
              size: 20,
            ),
            label: Text(
              _tabController.index == 0
                  ? 'Plan a Date 🍷'
                  : (_tabController.index == 1 ? 'Add Bucket Wish 🌟' : 'New Savings Goal 💰'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
          },
        );
      },
    );
  }

  // ==========================================
  // 1. DATE PLANS TAB
  // ==========================================
  Widget _buildDatePlansTab(String relationshipId, bool isDark) {
    return StreamBuilder<List<DatePlanModel>>(
      initialData: _plansRepository.getDatePlans(relationshipId),
      stream: _plansRepository.getDatePlansStream(relationshipId),
      builder: (context, snapshot) {
        final plans = snapshot.data ?? [];

        final filteredPlans = plans.where((p) {
          if (_dateCategoryFilter == 'All') return true;
          if (_dateCategoryFilter == 'Upcoming') return !p.isCompleted;
          if (_dateCategoryFilter == 'Completed') return p.isCompleted;
          return p.category.toLowerCase() == _dateCategoryFilter.toLowerCase();
        }).toList();

        return Column(
          children: [
            // Filter Pills
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Upcoming', 'Completed', 'Dinner', 'Cinema', 'Outdoor', 'Workshop', 'Trip'].map((cat) {
                    final isSelected = _dateCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.champagne.withOpacity(0.3),
                        checkmarkColor: AppColors.champagneDark,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? (isDark ? AppColors.champagne : AppColors.champagneDark)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        onSelected: (_) => setState(() => _dateCategoryFilter = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            Expanded(
              child: filteredPlans.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.champagne.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.event_available_rounded, size: 48, color: AppColors.champagneDark),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'No date plans in this filter',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Roll Date Idea" or "+" to plan your next romantic date!',
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 240, minWidth: 180),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.champagne,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.casino_rounded, size: 18),
                                label: const Text('Roll a Romantic Date 🎲', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () => _rollRandomDateIdea(relationshipId),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(

                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: filteredPlans.length,
                      itemBuilder: (context, index) {
                        final plan = filteredPlans[index];
                        final dateStr = DateFormat('EEE, MMM d • h:mm a').format(plan.scheduledFor);

                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Transform.scale(
                                scale: 1.1,
                                child: Checkbox(
                                  value: plan.isCompleted,
                                  activeColor: AppColors.champagneDark,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  onChanged: (val) {
                                    _plansRepository.toggleDatePlanCompleted(plan.id, val ?? false);
                                    if (val == true) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('🥂 Date completed! Cherish this sweet memory.'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.champagne.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            plan.category.toUpperCase(),
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.champagneDark),
                                          ),
                                        ),
                                        if (plan.budget > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${CurrencyService.symbol}${plan.budget.toStringAsFixed(0)}',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      plan.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        decoration: plan.isCompleted ? TextDecoration.lineThrough : null,
                                        color: plan.isCompleted ? Colors.grey : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 13, color: isDark ? Colors.white60 : Colors.black54),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (plan.locationName != null && plan.locationName!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.champagneDark),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              plan.locationName!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (plan.description != null && plan.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        plan.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, size: 18),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showAddDateModal(relationshipId, editPlan: plan);
                                  } else if (val == 'toggle') {
                                    _plansRepository.toggleDatePlanCompleted(plan.id, !plan.isCompleted);
                                  } else if (val == 'delete') {
                                    _plansRepository.deleteDatePlan(plan.id);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Text(plan.isCompleted ? 'Mark as Incomplete' : 'Mark as Completed'),
                                  ),
                                  const PopupMenuItem(value: 'edit', child: Text('Edit Date')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // 2. BUCKET LIST TAB
  // ==========================================
  Widget _buildBucketListTab(String relationshipId, bool isDark) {
    return StreamBuilder<List<BucketListItemModel>>(
      initialData: _plansRepository.getBucketList(relationshipId),
      stream: _plansRepository.getBucketListStream(relationshipId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        final filteredItems = items.where((b) {
          if (_bucketCategoryFilter == 'All') return true;
          if (_bucketCategoryFilter == 'Achieved') return b.isCompleted;
          if (_bucketCategoryFilter == 'Pending') return !b.isCompleted;
          return b.category.toLowerCase() == _bucketCategoryFilter.toLowerCase();
        }).toList();

        return Column(
          children: [
            // Filter Pills
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Pending', 'Achieved', 'Travel', 'Adventure', 'Experience', 'Milestone', 'Life'].map((cat) {
                    final isSelected = _bucketCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.champagne.withOpacity(0.3),
                        checkmarkColor: AppColors.champagneDark,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? (isDark ? AppColors.champagne : AppColors.champagneDark)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        onSelected: (_) => setState(() => _bucketCategoryFilter = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.champagne.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_border_rounded, size: 48, color: AppColors.champagneDark),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'No bucket list wishes in this filter',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add lifelong adventures and dreams you want to experience together!',
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 240, minWidth: 180),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.champagne,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add Bucket Wish ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () => _showAddBucketItemModal(relationshipId),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(

                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];

                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Transform.scale(
                                scale: 1.1,
                                child: Checkbox(
                                  value: item.isCompleted,
                                  activeColor: AppColors.champagneDark,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  onChanged: (val) {
                                    _plansRepository.toggleBucketItemCompleted(item.id, val ?? false);
                                    if (val == true) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('🌟 Bucket wish achieved! Another dream fulfilled together.'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.champagne.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.category.toUpperCase(),
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.champagneDark),
                                          ),
                                        ),
                                        if (item.targetDate != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              DateFormat('MMM yyyy').format(item.targetDate!),
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                        color: item.isCompleted ? Colors.grey : null,
                                      ),
                                    ),
                                    if (item.description != null && item.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, size: 18),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showAddBucketItemModal(relationshipId, editItem: item);
                                  } else if (val == 'toggle') {
                                    _plansRepository.toggleBucketItemCompleted(item.id, !item.isCompleted);
                                  } else if (val == 'delete') {
                                    _plansRepository.deleteBucketListItem(item.id);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Text(item.isCompleted ? 'Mark as Pending' : 'Mark as Achieved'),
                                  ),
                                  const PopupMenuItem(value: 'edit', child: Text('Edit Wish')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // 3. SHARED GOALS TAB
  // ==========================================
  Widget _buildGoalsTab(String relationshipId, bool isDark) {
    return StreamBuilder<List<SharedGoalModel>>(
      initialData: _plansRepository.getSharedGoals(relationshipId),
      stream: _plansRepository.getSharedGoalsStream(relationshipId),
      builder: (context, snapshot) {
        final goals = snapshot.data ?? [];

        final totalSaved = goals.fold<double>(0, (sum, g) => sum + g.currentAmount);
        final totalTarget = goals.fold<double>(0, (sum, g) => sum + g.targetAmount);
        final completedCount = goals.where((g) => g.isCompleted).length;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Savings Overview Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.champagneDark, AppColors.champagne, AppColors.champagneLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.champagneDark.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.savings_rounded, color: Colors.black87, size: 20),
                          SizedBox(width: 8),
                          Text('Shared Savings & Milestones', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${CurrencyService.symbol}${totalSaved.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
                              ),
                              const Text('Total Shared Savings', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$completedCount / ${goals.length} Goals Reached',
                              style: const TextStyle(color: AppColors.champagne, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (goals.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.champagne.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.savings_rounded, size: 48, color: AppColors.champagneDark),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'No shared goals yet',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first shared savings goal for trips, home, or dates!',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240, minWidth: 180),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.champagne,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Create Shared Goal 💰', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () => _showAddGoalModal(relationshipId),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final goal = goals[index];
                      final percent = (goal.progressPercentage * 100).toInt();

                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.champagne.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    goal.category.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.champagneDark),
                                  ),
                                ),
                                const Spacer(),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                                  onSelected: (val) {
                                    if (val == 'contribute') {
                                      _showContributeModal(goal);
                                    } else if (val == 'edit') {
                                      _showAddGoalModal(relationshipId, editGoal: goal);
                                    } else if (val == 'delete') {
                                      _plansRepository.deleteSharedGoal(goal.id);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(value: 'contribute', child: Text('Add Contribution 💰')),
                                    const PopupMenuItem(value: 'edit', child: Text('Edit Goal')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    goal.title,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$percent%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: goal.isCompleted ? Colors.green : AppColors.champagneDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: goal.progressPercentage,
                                minHeight: 10,
                                backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  goal.isCompleted ? Colors.green : AppColors.champagne,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${CurrencyService.symbol}${goal.currentAmount.toStringAsFixed(0)} saved',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Target: ${CurrencyService.symbol}${goal.targetAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                if (goal.isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                                        SizedBox(width: 6),
                                        Text('Goal Achieved! 🎉', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  )
                                else
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                                      foregroundColor: isDark ? Colors.white : Colors.black87,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.champagneDark),
                                    label: const Text('Add Money', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    onPressed: () => _showContributeModal(goal),
                                  ),
                                const Spacer(),
                                if (goal.targetDate != null)
                                  Text(
                                    'Target: ${DateFormat('MMM yyyy').format(goal.targetDate!)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
                    },
                    childCount: goals.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
