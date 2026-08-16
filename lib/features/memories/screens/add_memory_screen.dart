import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../couple_connection/bloc/couple_bloc.dart';
import '../../couple_connection/bloc/couple_state.dart';
import '../repositories/memories_repository.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _memoriesRepository = MemoriesRepository();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Milestone';
  bool _isLoading = false;
  final List<File> _selectedImages = [];
  final _picker = ImagePicker();

  final List<String> _categories = [
    'Milestone',
    'First Trip',
    'Anniversary',
    'Date Night',
    'Adventures',
    'Cozy Days',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _selectedImages.add(File(picked.path));
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMemory() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final coupleState = context.read<CoupleBloc>().state;
    if (coupleState is! CouplePaired) return;

    setState(() => _isLoading = true);

    try {
      await _memoriesRepository.createMemory(
        relationshipId: coupleState.relationship.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        memoryDate: _selectedDate,
        locationName: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        category: _selectedCategory,
        imageFiles: _selectedImages,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memory saved to timeline! ✨'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving memory: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Shared Memory', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Memory Title
                CustomTextField(
                  controller: _titleController,
                  hintText: 'e.g. Stargazing at Joshua Tree',
                  labelText: 'Memory Title',
                  prefixIcon: Icons.auto_awesome_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter a title';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // 2. Date of Memory
                Text(
                  'Date of Memory',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.champagne),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('MMMM d, yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiaryDark, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 3. Category Chips
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.champagne.withOpacity(0.22)
                              : (isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.champagne : (isDark ? AppColors.darkBorder : Colors.transparent),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check_rounded, size: 14, color: AppColors.champagneDark),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.champagneDark
                                    : (isDark ? AppColors.textSecondaryDark : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // 4. Location
                CustomTextField(
                  controller: _locationController,
                  hintText: 'e.g. Joshua Tree National Park',
                  labelText: 'Location (Optional)',
                  prefixIcon: Icons.location_on_outlined,
                ),

                const SizedBox(height: 18),

                // 5. Story & Feelings
                CustomTextField(
                  controller: _descriptionController,
                  hintText: 'Write down thoughts, inside jokes, and feelings from that day...',
                  labelText: 'Story & Feelings',
                  maxLines: 4,
                ),

                const SizedBox(height: 18),

                // 6. Photos Attachment Preview
                Text(
                  'Photos & Moments',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.champagne.withOpacity(0.5)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: AppColors.champagne, size: 24),
                              SizedBox(height: 4),
                              Text('Add Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.champagneDark)),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        ..._selectedImages.asMap().entries.map((entry) {
                          final i = entry.key;
                          final file = entry.value;
                          return Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedImages.removeAt(i)),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                if (_selectedImages.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Add romantic photos or snapshots (Optional)',
                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                ],

                const SizedBox(height: 32),

                // 7. Save Button
                CustomButton(
                  text: 'Save Memory to Timeline ✨',
                  icon: Icons.check_rounded,
                  onPressed: _saveMemory,
                  isLoading: _isLoading,
                  variant: ButtonVariant.primary,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
