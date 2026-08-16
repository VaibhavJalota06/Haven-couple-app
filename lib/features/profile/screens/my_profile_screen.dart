import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/models/user_profile.dart';
import '../../discover/models/post_model.dart';
import '../../discover/repositories/discover_repository.dart';
import '../../discover/screens/fullscreen_reels_viewer.dart';
import '../../discover/screens/story_viewer_screen.dart';
import '../../privacy_center/screens/privacy_center_screen.dart';
import 'account_center_screen.dart';
import 'edit_profile_screen.dart';
import 'post_detail_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  UserProfile _user = UserProfile(
    id: 'usr_me',
    email: 'vaibhav@example.com',
    fullName: 'Vaibhav Jalota',
    nickname: 'Vaibh',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
    coverUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&q=80',
    bio: 'Visual designer & adventurer ✨ Living every moment fully with you ❤️',
    work: 'Product Designer & Photographer',
    education: 'Studied at Stanford University',
    currentCity: 'Lives in San Francisco, California',
    hometown: 'From Los Angeles, California',
    relationshipStatus: 'In a relationship with Maya Lin ❤️',
    website: 'instagram.com/vaibhavjalota',
    hobbies: const ['Photography 📷', 'Travel ✈️', 'Cooking 🍳', 'Coffee ☕', 'Indie Music 🎧'],
    mood: 'loved',
    createdAt: DateTime.now().subtract(const Duration(days: 180)),
  );

  final List<Map<String, String>> _highlights = [];
  final List<PostItemData> _postItems = [];
  final List<PostModel> _reelItems = [];

  void _showAddPostDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final captionCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String? selectedImageUrl;

    final samplePhotos = [
      'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=600&q=80',
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80',
      'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600&q=80',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&q=80',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              // Photo picker row
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: samplePhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final photo = samplePhotos[index];
                    final isSelected = selectedImageUrl == photo;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedImageUrl = photo),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.champagne : Colors.transparent,
                            width: 2.5,
                          ),
                          image: DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover),
                        ),
                        child: isSelected
                            ? const Center(child: Icon(Icons.check_circle_rounded, color: AppColors.champagne, size: 28))
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: captionCtrl,
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                  hintText: 'Add location (e.g. Paris, France)',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.champagne),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.champagne,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Share Post', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (selectedImageUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a photo first')),
                      );
                      return;
                    }
                    final caption = captionCtrl.text.trim().isNotEmpty ? captionCtrl.text.trim() : 'Special memory ✨';
                    final location = locationCtrl.text.trim();
                    final imgUrl = selectedImageUrl!;

                    setState(() {
                      _postItems.insert(
                        0,
                        PostItemData(
                          id: 'post_${DateTime.now().millisecondsSinceEpoch}',
                          imageUrl: imgUrl,
                          location: location,
                          caption: caption,
                          likesCount: 1,
                          isLiked: true,
                          createdAt: DateTime.now(),
                          comments: [],
                        ),
                      );
                    });

                    // Persist to Supabase posts table
                    DiscoverRepository().createPost(
                      mediaUrl: imgUrl,
                      caption: caption,
                      locationName: location.isNotEmpty ? location : null,
                      mediaType: PostMediaType.photo,
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post published to your grid! 📸✨')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateUser(UserProfile updated) {
    setState(() => _user = updated);
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
  }

  void _openEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          user: _user,
          onProfileUpdated: _updateUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          // Merge state user with local fields
          _user = _user.copyWith(
            fullName: state.user.fullName,
            nickname: state.user.nickname,
            avatarUrl: state.user.avatarUrl ?? _user.avatarUrl,
            coverUrl: state.user.coverUrl ?? _user.coverUrl,
            bio: state.user.bio ?? _user.bio,
            work: state.user.work ?? _user.work,
            education: state.user.education ?? _user.education,
            currentCity: state.user.currentCity ?? _user.currentCity,
            hometown: state.user.hometown ?? _user.hometown,
            relationshipStatus: state.user.relationshipStatus ?? _user.relationshipStatus,
            website: state.user.website ?? _user.website,
            hobbies: state.user.hobbies.isNotEmpty ? state.user.hobbies : _user.hobbies,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(
                  _user.nickname ?? _user.fullName.toLowerCase().replaceAll(' ', '_'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.verified_rounded, color: AppColors.champagne, size: 18),
              ],
            ),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.champagne),
                tooltip: 'Edit Profile',
                onPressed: _openEditProfile,
              ),
              IconButton(
                icon: const Icon(Icons.hub_rounded, color: AppColors.champagne),
                tooltip: 'Accounts Center',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AccountCenterScreen()),
                  );
                },
              ),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Cover Photo & Avatar Header
                      _buildHeaderCover(isDark),

                      const SizedBox(height: 12),

                      // 2. Name & Editable Bio
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _user.fullName,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.champagne),
                                  tooltip: 'Edit Name & Bio',
                                  onPressed: _showEditBioModal,
                                ),
                              ],
                            ),
                            if (_user.bio != null && _user.bio!.isNotEmpty) ...[
                              InkWell(
                                onTap: _showEditBioModal,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    _user.bio!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (_user.relationshipStatus != null && _user.relationshipStatus!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _showRelationshipPickerModal,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.roseDust.withOpacity(0.35), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.favorite_rounded, color: AppColors.roseDust, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        _user.relationshipStatus!,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.champagne),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 3. Action Buttons (Edit Profile, Accounts Center, Privacy)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.champagne,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  onPressed: _openEditProfile,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.edit_rounded, size: 16),
                                      SizedBox(width: 6),
                                      Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                                    foregroundColor: isDark ? Colors.white : Colors.black87,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const AccountCenterScreen()),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.hub_rounded, size: 16, color: AppColors.champagne),
                                      SizedBox(width: 6),
                                      Text('Accounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.security_rounded, size: 18, color: AppColors.champagne),
                                tooltip: 'Privacy Center',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const PrivacyCenterScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. Facebook-style Details (About Card - Fully Interactive)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'About Details',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.champagne),
                                  ),
                                  InkWell(
                                    onTap: _showEditDetailsModal,
                                    child: const Row(
                                      children: [
                                        Icon(Icons.edit_rounded, size: 14, color: AppColors.champagne),
                                        SizedBox(width: 4),
                                        Text('Edit', style: TextStyle(fontSize: 12, color: AppColors.champagne, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildDetailRow(
                                Icons.work_outline_rounded,
                                _user.work ?? 'Product Designer & Photographer',
                                onTap: () => _showSingleFieldEditor('Work / Title', _user.work ?? '', (v) => _updateUser(_user.copyWith(work: v))),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                Icons.school_outlined,
                                _user.education ?? 'Studied at Stanford University',
                                onTap: () => _showSingleFieldEditor('Education', _user.education ?? '', (v) => _updateUser(_user.copyWith(education: v))),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                Icons.home_outlined,
                                _user.currentCity ?? 'Lives in San Francisco, California',
                                onTap: () => _showSingleFieldEditor('Current City', _user.currentCity ?? '', (v) => _updateUser(_user.copyWith(currentCity: v))),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                Icons.location_on_outlined,
                                _user.hometown ?? 'From Los Angeles, California',
                                onTap: () => _showSingleFieldEditor('Hometown', _user.hometown ?? '', (v) => _updateUser(_user.copyWith(hometown: v))),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                Icons.favorite_rounded,
                                _user.relationshipStatus ?? 'In a relationship with Maya Lin ❤️',
                                color: AppColors.roseDust,
                                onTap: () => _showRelationshipPickerModal(),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                Icons.link_rounded,
                                _user.website ?? 'instagram.com/vaibhavjalota',
                                color: AppColors.champagne,
                                onTap: () => _showSingleFieldEditor('Website / Link', _user.website ?? '', (v) => _updateUser(_user.copyWith(website: v))),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 5. Hobbies & Interests Tray
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Hobbies & Interests',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                GestureDetector(
                                  onTap: _showAddHobbyDialog,
                                  child: const Text('+ Add', style: TextStyle(color: AppColors.champagne, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._user.hobbies.map(
                                  (h) => Chip(
                                    label: Text(h, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                                    deleteIcon: const Icon(Icons.close, size: 14),
                                    onDeleted: () {
                                      final updatedList = List<String>.from(_user.hobbies)..remove(h);
                                      _updateUser(_user.copyWith(hobbies: updatedList));
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 6. Story Highlights Tray (Interactive + Add Highlight)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text('Story Highlights', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _highlights.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return GestureDetector(
                                onTap: _showAddHighlightDialog,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade200,
                                        border: Border.all(color: AppColors.champagne.withOpacity(0.5)),
                                      ),
                                      child: const Icon(Icons.add_rounded, color: AppColors.champagne, size: 28),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text('New', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              );
                            }
                            final hl = _highlights[index - 1];
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StoryViewerScreen(
                                      user: _user,
                                      storyMediaUrls: [hl['image']!],
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 27,
                                      backgroundImage: NetworkImage(hl['image']!),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    hl['title']!,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // 7. Tab Bar (Posts, Reels, Saved)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: isDark ? Colors.white : Colors.black,
                      dividerColor: Colors.transparent,
                      dividerHeight: 0,
                      indicatorWeight: 1.5,
                      labelColor: isDark ? Colors.white : Colors.black,
                      unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_on_rounded)),
                        Tab(icon: Icon(Icons.video_library_rounded)),
                        Tab(icon: Icon(Icons.bookmark_outline_rounded)),
                      ],
                    ),
                    isDark: isDark,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // 1. Grid of My Posts (Interactive -> Opens PostDetailScreen or Empty State)
                _postItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.photo_camera_outlined, size: 36, color: AppColors.champagne),
                            ),
                            const SizedBox(height: 12),
                            const Text('No Posts Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            const Text('Photos you share with your partner will appear here.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.champagne,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _showAddPostDialog,
                              icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                              label: const Text('Share First Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(2),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: _postItems.length,
                        itemBuilder: (context, index) {
                          final post = _postItems[index];
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(
                                    user: _user,
                                    posts: _postItems,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: Image.network(post.imageUrl, fit: BoxFit.cover),
                          );
                        },
                      ),

                // 2. Reels Grid (Interactive -> Opens FullscreenReelsViewer or Empty State)
                _reelItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.movie_creation_outlined, size: 36, color: AppColors.champagne),
                            ),
                            const SizedBox(height: 12),
                            const Text('No Reels Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            const Text('Capture and share couple video reels.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(2),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                          childAspectRatio: 9 / 16,
                        ),
                        itemCount: _reelItems.length,
                        itemBuilder: (context, index) {
                          final reel = _reelItems[index];
                          final views = ['45.2K', '18.9K', '89.1K'][index % 3];

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FullscreenReelsViewer(
                                    reels: _reelItems,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(reel.mediaUrl, fit: BoxFit.cover),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 2),
                                      Text(views, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                // 3. Saved Moments (Interactive -> Opens PostDetailScreen)
                Builder(
                  builder: (context) {
                    final savedPosts = _postItems.where((p) => p.isSaved).toList();

                    if (savedPosts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bookmark_border_rounded, size: 36, color: AppColors.champagne),
                            ),
                            const SizedBox(height: 12),
                            const Text('No Saved Posts Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            const Text('Bookmark special couple photos to view them here.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(2),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: savedPosts.length,
                      itemBuilder: (context, index) {
                        final post = savedPosts[index];
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PostDetailScreen(
                                  user: _user,
                                  posts: savedPosts,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(post.imageUrl, fit: BoxFit.cover),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.bookmark_rounded, color: AppColors.champagne, size: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCover(bool isDark) {
    final cover = _user.coverUrl ?? 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&q=80';
    final screenWidth = MediaQuery.of(context).size.width;
    final coverHeight = (screenWidth * 0.42).clamp(140.0, 240.0);
    final avatarRadius = (screenWidth * 0.11).clamp(38.0, 52.0);

    return Container(
      margin: EdgeInsets.only(bottom: avatarRadius + 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover Photo
          Container(
            height: coverHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(image: getImageProvider(cover)!, fit: BoxFit.cover),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: GestureDetector(
                    onTap: _showCoverPickerModal,
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
                          Text('Edit Cover', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile Picture (Centered or responsive left aligned)
          Positioned(
            bottom: -avatarRadius,
            left: 16,
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
                    backgroundImage: getImageProvider(_user.avatarUrl),
                    child: _user.avatarUrl == null
                        ? Text(_user.fullName.isNotEmpty ? _user.fullName[0] : 'U', style: TextStyle(fontSize: avatarRadius * 0.7))
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: _showAvatarPickerModal,
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
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color ?? Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildModalField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    IconData? icon,
    int maxLines = 1,
    int? maxLength,
    String? hintText,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.champagne : AppColors.champagneDark,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
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

  void _showEditBioModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bioController = TextEditingController(text: _user.bio ?? '');
    final nameController = TextEditingController(text: _user.fullName);
    final nicknameController = TextEditingController(text: _user.nickname ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Bio & Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildModalField(label: 'Full Name', controller: nameController, isDark: isDark, icon: Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _buildModalField(label: 'Nickname / Handle', controller: nicknameController, isDark: isDark, icon: Icons.alternate_email_rounded),
              const SizedBox(height: 12),
              _buildModalField(label: 'Bio', controller: bioController, isDark: isDark, maxLines: 3, maxLength: 150, hintText: 'Tell your story...'),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Save',
                onPressed: () {
                  _updateUser(
                    _user.copyWith(
                      fullName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : _user.fullName,
                      nickname: nicknameController.text.trim().isNotEmpty ? nicknameController.text.trim() : null,
                      bio: bioController.text.trim(),
                    ),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bio updated! ✨')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSingleFieldEditor(String title, String initialValue, Function(String) onSave) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: initialValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildModalField(label: title, controller: controller, isDark: isDark, autofocus: true),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Save',
              onPressed: () {
                onSave(controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title updated! ✨')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDetailsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workCtrl = TextEditingController(text: _user.work ?? '');
    final eduCtrl = TextEditingController(text: _user.education ?? '');
    final cityCtrl = TextEditingController(text: _user.currentCity ?? '');
    final homeCtrl = TextEditingController(text: _user.hometown ?? '');
    final webCtrl = TextEditingController(text: _user.website ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit About Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildModalField(label: 'Work / Title', controller: workCtrl, isDark: isDark, icon: Icons.work_outline_rounded),
              const SizedBox(height: 12),
              _buildModalField(label: 'Education', controller: eduCtrl, isDark: isDark, icon: Icons.school_outlined),
              const SizedBox(height: 12),
              _buildModalField(label: 'Current City', controller: cityCtrl, isDark: isDark, icon: Icons.home_outlined),
              const SizedBox(height: 12),
              _buildModalField(label: 'Hometown', controller: homeCtrl, isDark: isDark, icon: Icons.location_on_outlined),
              const SizedBox(height: 12),
              _buildModalField(label: 'Website / Link', controller: webCtrl, isDark: isDark, icon: Icons.link_rounded),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Save Details',
                onPressed: () {
                  _updateUser(
                    _user.copyWith(
                      work: workCtrl.text.trim(),
                      education: eduCtrl.text.trim(),
                      currentCity: cityCtrl.text.trim(),
                      hometown: homeCtrl.text.trim(),
                      website: webCtrl.text.trim(),
                    ),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details saved successfully! ✨')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRelationshipPickerModal() {
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
            const Text('Relationship Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ...options.map(
              (opt) => ListTile(
                leading: const Icon(Icons.favorite_rounded, color: AppColors.roseDust),
                title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: _user.relationshipStatus == opt
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.champagne)
                    : null,
                onTap: () {
                  _updateUser(_user.copyWith(relationshipStatus: opt));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relationship status updated! ❤️')));
                },
              ),
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
        if (isAvatar) {
          _updateUser(_user.copyWith(avatarUrl: picked.path));
        } else {
          _updateUser(_user.copyWith(coverUrl: picked.path));
        }
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

  void _showAvatarPickerModal() {
    final presets = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&q=80',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
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
            const Text('Curated Presets', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  return GestureDetector(
                    onTap: () {
                      _updateUser(_user.copyWith(avatarUrl: presets[i]));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated! 📷')));
                    },
                    child: CircleAvatar(radius: 30, backgroundImage: NetworkImage(presets[i])),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'More Options in Edit Profile',
              variant: ButtonVariant.secondary,
              onPressed: () {
                Navigator.pop(ctx);
                _openEditProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCoverPickerModal() {
    final covers = [
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&q=80',
      'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=1000&q=80',
      'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=1000&q=80',
      'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=1000&q=80',
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
            const Text('Change Cover Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            const Text('Curated Presets', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: covers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  return GestureDetector(
                    onTap: () {
                      _updateUser(_user.copyWith(coverUrl: covers[i]));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cover photo updated! 🌄')));
                    },
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: NetworkImage(covers[i]), fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'More Options in Edit Profile',
              variant: ButtonVariant.secondary,
              onPressed: () {
                Navigator.pop(ctx);
                _openEditProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHobbyDialog() {
    final hobbyController = TextEditingController();
    final suggestions = ['Stargazing 🌌', 'Roadtrips 🚗', 'Gaming 🎮', 'Wine Tasting 🍷', 'Baking 🧁', 'Fitness 💪'];

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
              decoration: const InputDecoration(hintText: 'e.g. Hiking 🥾, Pottery 🏺', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const Text('Suggestions', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestions.map(
                (sug) => ActionChip(
                  label: Text(sug, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    if (!_user.hobbies.contains(sug)) {
                      final updated = List<String>.from(_user.hobbies)..add(sug);
                      _updateUser(_user.copyWith(hobbies: updated));
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
                final updated = List<String>.from(_user.hobbies)..add(hobbyController.text.trim());
                _updateUser(_user.copyWith(hobbies: updated));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddHighlightDialog() {
    final titleController = TextEditingController();
    final sampleImages = [
      'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=300&q=80',
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300&q=80',
      'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=300&q=80',
    ];
    String selectedImg = sampleImages.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Story Highlight'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Highlight Title', hintText: 'e.g. Summer ☀️', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('Select Cover Photo', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: sampleImages.map((img) {
                  final isSelected = img == selectedImg;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedImg = img),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? AppColors.champagne : Colors.transparent, width: 3),
                      ),
                      child: CircleAvatar(radius: 24, backgroundImage: NetworkImage(img)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.champagne),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  setState(() {
                    _highlights.add({
                      'title': titleController.text.trim(),
                      'image': selectedImg,
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story highlight created! ✨')));
                }
              },
              child: const Text('Create', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this.tabBar, {required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.darkBackground : Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
