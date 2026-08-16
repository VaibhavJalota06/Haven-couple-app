import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/models/user_profile.dart';

ImageProvider? getImageProvider(String? pathOrUrl) {
  if (pathOrUrl == null || pathOrUrl.isEmpty) return null;
  if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
    return NetworkImage(pathOrUrl);
  }
  return FileImage(File(pathOrUrl));
}

class EditProfileScreen extends StatefulWidget {
  final UserProfile user;
  final Function(UserProfile updatedUser)? onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.user,
    this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _bioController;
  late TextEditingController _workController;
  late TextEditingController _educationController;
  late TextEditingController _cityController;
  late TextEditingController _hometownController;
  late TextEditingController _relationshipController;
  late TextEditingController _linksController;

  String? _avatarUrl;
  String? _coverUrl;
  late List<String> _hobbies;

  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&q=80',
  ];

  final List<String> _presetCovers = [
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&q=80',
    'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=1000&q=80',
    'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=1000&q=80',
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=1000&q=80',
    'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1000&q=80',
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1000&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _nicknameController = TextEditingController(text: widget.user.nickname ?? 'Vaibh');
    _bioController = TextEditingController(text: widget.user.bio ?? 'Visual designer & adventurer ✨ Living every moment fully with you ❤️');
    _workController = TextEditingController(text: widget.user.work ?? 'Product Designer & Photographer');
    _educationController = TextEditingController(text: widget.user.education ?? 'Stanford University');
    _cityController = TextEditingController(text: widget.user.currentCity ?? 'San Francisco, California');
    _hometownController = TextEditingController(text: widget.user.hometown ?? 'Los Angeles, California');
    _relationshipController = TextEditingController(text: widget.user.relationshipStatus ?? 'In a relationship with Maya Lin ❤️');
    _linksController = TextEditingController(text: widget.user.website ?? 'instagram.com/vaibhavjalota');

    _avatarUrl = widget.user.avatarUrl ?? _presetAvatars.first;
    _coverUrl = widget.user.coverUrl ?? _presetCovers.first;
    _hobbies = List<String>.from(widget.user.hobbies);
    _showRelationshipOnProfile = widget.user.relationshipStatus != null && widget.user.relationshipStatus!.isNotEmpty;
  }

  bool _showRelationshipOnProfile = true;

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _bioController.dispose();
    _workController.dispose();
    _educationController.dispose();
    _cityController.dispose();
    _hometownController.dispose();
    _relationshipController.dispose();
    _linksController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final updated = widget.user.copyWith(
      fullName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : widget.user.fullName,
      nickname: _nicknameController.text.trim().isNotEmpty ? _nicknameController.text.trim() : null,
      avatarUrl: _avatarUrl,
      coverUrl: _coverUrl,
      bio: _bioController.text.trim(),
      work: _workController.text.trim(),
      education: _educationController.text.trim(),
      currentCity: _cityController.text.trim(),
      hometown: _hometownController.text.trim(),
      relationshipStatus: _showRelationshipOnProfile ? _relationshipController.text.trim() : '',
      website: _linksController.text.trim(),
      hobbies: _hobbies,
    );

    widget.onProfileUpdated?.call(updated);

    // Also update AuthBloc
    context.read<AuthBloc>().add(
      AuthProfileUpdateRequested(
        fullName: updated.fullName,
        nickname: updated.nickname,
        avatarUrl: updated.avatarUrl,
        coverUrl: updated.coverUrl,
        bio: updated.bio,
        work: updated.work,
        education: updated.education,
        currentCity: updated.currentCity,
        hometown: updated.hometown,
        relationshipStatus: updated.relationshipStatus,
        website: updated.website,
        hobbies: updated.hobbies,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully! ✨')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save', style: TextStyle(color: AppColors.champagne, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Profile & Cover Photos Section
          _buildPhotosEditor(isDark),

          const SizedBox(height: 24),

          // 2. Avatar / 3D Bitmoji
          _buildEditRow(
            title: '3D Avatar & Memoji',
            trailingText: 'Customize Style',
            onTap: _showAvatarStyleSheet,
          ),

          const SizedBox(height: 18),

          // 3. Bio Section
          _buildSectionTitle('Bio'),
          const SizedBox(height: 6),
          TextField(
            controller: _bioController,
            maxLines: 3,
            maxLength: 150,
            decoration: InputDecoration(
              hintText: 'Describe yourself and your story...',
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 18),

          // 4. Basic Info
          _buildSectionTitle('Basic Info'),
          const SizedBox(height: 8),
          _buildTextField('Full Name', _nameController, isDark, icon: Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _buildTextField('Nickname / Handle', _nicknameController, isDark, icon: Icons.alternate_email_rounded),
          const SizedBox(height: 12),
          _buildTextField('Links / Website', _linksController, isDark, icon: Icons.link_rounded),

          const SizedBox(height: 24),

          // 5. Facebook / Messenger Style "Details" (About Info)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Details (About Info)'),
              GestureDetector(
                onTap: _showQuickEditDetailsSheet,
                child: const Text('Quick Edit', style: TextStyle(color: AppColors.champagne, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField('Work / Title', _workController, isDark, icon: Icons.work_outline_rounded),
          const SizedBox(height: 12),
          _buildTextField('Education', _educationController, isDark, icon: Icons.school_outlined),
          const SizedBox(height: 12),
          _buildTextField('Current City', _cityController, isDark, icon: Icons.home_outlined),
          const SizedBox(height: 12),
          _buildTextField('Hometown', _hometownController, isDark, icon: Icons.location_on_outlined),
          const SizedBox(height: 12),
          _buildRelationshipField(isDark),

          const SizedBox(height: 24),

          // 6. Hobbies & Interests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Hobbies & Interests'),
              GestureDetector(
                onTap: _showAddHobbyDialog,
                child: const Text('+ Add Hobby', style: TextStyle(color: AppColors.champagne, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._hobbies.map(
                (hobby) => Chip(
                  label: Text(hobby, style: const TextStyle(fontSize: 12)),
                  backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _hobbies.remove(hobby));
                  },
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16, color: AppColors.champagne),
                label: const Text('Add Hobby', style: TextStyle(fontSize: 12, color: AppColors.champagne)),
                backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                onPressed: _showAddHobbyDialog,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Save Button
          CustomButton(
            text: 'Save Changes',
            onPressed: _saveProfile,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPhotosEditor(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final coverHeight = (screenWidth * 0.38).clamp(130.0, 220.0);
    final avatarRadius = (screenWidth * 0.11).clamp(36.0, 50.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Cover & Profile Photo'),
        const SizedBox(height: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover Photo
            Container(
              height: coverHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: _coverUrl != null
                    ? DecorationImage(image: getImageProvider(_coverUrl!)!, fit: BoxFit.cover)
                    : null,
                color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade300,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: _showCoverPickerSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Edit Cover', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Profile Picture
            Positioned(
              bottom: -avatarRadius * 0.75,
              left: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkBackground : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                      backgroundImage: getImageProvider(_avatarUrl),
                      child: _avatarUrl == null ? const Icon(Icons.person, size: 36) : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _showAvatarPickerSheet,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.champagne,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkBackground : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: avatarRadius + 4),
      ],
    );
  }

  Widget _buildRelationshipField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with ON/OFF Toggle Switch Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Relationship Status',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _showRelationshipOnProfile = !_showRelationshipOnProfile;
                });
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _showRelationshipOnProfile
                          ? 'Relationship Status is now ON (Shown on Profile) ❤️'
                          : 'Relationship Status is now OFF (Hidden from Profile) 🔒',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _showRelationshipOnProfile
                      ? AppColors.champagne.withOpacity(0.18)
                      : (isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showRelationshipOnProfile
                        ? AppColors.champagneDark.withOpacity(0.6)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showRelationshipOnProfile ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      size: 14,
                      color: _showRelationshipOnProfile ? AppColors.champagne : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showRelationshipOnProfile ? 'Show: ON' : 'Show: OFF',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _showRelationshipOnProfile
                            ? (isDark ? AppColors.champagne : AppColors.champagneDark)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Interactive Selector Box
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showRelationshipPickerSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _showRelationshipOnProfile
                    ? AppColors.roseDust.withOpacity(0.4)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _showRelationshipOnProfile ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20,
                  color: _showRelationshipOnProfile ? AppColors.roseDust : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _relationshipController.text.isNotEmpty
                            ? _relationshipController.text
                            : 'Select relationship status...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _showRelationshipOnProfile
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.grey,
                        ),
                      ),
                      if (!_showRelationshipOnProfile)
                        const Text(
                          'Hidden from public profile. Tap toggle above to turn ON.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.champagne, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.champagne : AppColors.champagneDark,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.champagne) : null,
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildEditRow({required String title, required String trailingText, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(trailingText, style: const TextStyle(color: AppColors.champagne, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.champagne),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, bool isAvatar) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (picked != null) {
        setState(() {
          if (isAvatar) {
            _avatarUrl = picked.path;
          } else {
            _coverUrl = picked.path;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAvatar ? 'Profile picture updated! 📷' : 'Cover photo updated! 🌄',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showAvatarPickerSheet() {
    final urlController = TextEditingController(text: _avatarUrl);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Profile Picture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Gallery & Camera Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.champagne,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery, true);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.champagne),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.champagne),
                    label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.champagne)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera, true);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Text('Curated Aesthetics', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _presetAvatars.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final url = _presetAvatars[i];
                  final isSelected = url == _avatarUrl;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _avatarUrl = url);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.champagne : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(url),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text('Or Paste Custom Image URL', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Set Profile Picture',
              onPressed: () {
                if (urlController.text.trim().isNotEmpty) {
                  setState(() => _avatarUrl = urlController.text.trim());
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCoverPickerSheet() {
    final urlController = TextEditingController(text: _coverUrl);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Cover Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Gallery & Camera Buttons for Cover
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.champagne,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text('Upload Cover', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery, false);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.champagne),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.champagne),
                    label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.champagne)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera, false);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Text('Aesthetic Presets', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _presetCovers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final url = _presetCovers[i];
                  final isSelected = url == _coverUrl;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _coverUrl = url);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.champagne : Colors.transparent,
                          width: 3,
                        ),
                        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text('Or Paste Custom Cover URL', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Set Cover Photo',
              onPressed: () {
                if (urlController.text.trim().isNotEmpty) {
                  setState(() => _coverUrl = urlController.text.trim());
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRelationshipPickerSheet() {
    final options = [
      'In a relationship with Maya Lin ❤️',
      'Engaged to Maya Lin 💍',
      'Married to Maya Lin 👰‍♀️🤵‍♂️',
      'It\'s complicated with Maya Lin ✨',
      'In an open relationship with Maya Lin 🥂',
      'Celebrating 2 Years Together 🎉',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Relationship Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ...options.map(
              (opt) => ListTile(
                leading: const Icon(Icons.favorite_rounded, color: AppColors.roseDust),
                title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: _relationshipController.text == opt
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.champagne)
                    : null,
                onTap: () {
                  setState(() => _relationshipController.text = opt);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarStyleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('3D Avatar & Memoji Creator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choose hair, expression, glasses, and outfit style.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildAvatarOptionChip('Smiling 😊', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80'),
                _buildAvatarOptionChip('Glasses 👓', 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&q=80'),
                _buildAvatarOptionChip('Cool 🕶️', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80'),
                _buildAvatarOptionChip('Artist 🎨', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80'),
              ],
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Save Avatar Style',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Avatar style updated! 🎨')),
                );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOptionChip(String label, String url) {
    return GestureDetector(
      onTap: () {
        setState(() => _avatarUrl = url);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _avatarUrl == url ? AppColors.champagne.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _avatarUrl == url ? AppColors.champagne : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 14, backgroundImage: NetworkImage(url)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showQuickEditDetailsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quick Edit About Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextField('Work / Title', _workController, Theme.of(context).brightness == Brightness.dark, icon: Icons.work_outline_rounded),
              const SizedBox(height: 12),
              _buildTextField('Education', _educationController, Theme.of(context).brightness == Brightness.dark, icon: Icons.school_outlined),
              const SizedBox(height: 12),
              _buildTextField('Current City', _cityController, Theme.of(context).brightness == Brightness.dark, icon: Icons.home_outlined),
              const SizedBox(height: 12),
              _buildTextField('Hometown', _hometownController, Theme.of(context).brightness == Brightness.dark, icon: Icons.location_on_outlined),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Done',
                onPressed: () {
                  setState(() {});
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddHobbyDialog() {
    final hobbyController = TextEditingController();
    final suggestions = [
      'Stargazing 🌌',
      'Roadtrips 🚗',
      'Gaming 🎮',
      'Wine Tasting 🍷',
      'Baking 🧁',
      'Fitness & Gym 💪',
      'Museums 🏛️',
      'Board Games 🎲',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Hobby / Interest'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: hobbyController,
              decoration: const InputDecoration(
                hintText: 'e.g. Hiking 🥾, Pottery 🏺',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Suggestions', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestions.map(
                (sug) => ActionChip(
                  label: Text(sug, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    if (!_hobbies.contains(sug)) {
                      setState(() => _hobbies.add(sug));
                    }
                    Navigator.pop(ctx);
                  },
                ),
              ).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.champagne),
            onPressed: () {
              if (hobbyController.text.trim().isNotEmpty) {
                setState(() => _hobbies.add(hobbyController.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
