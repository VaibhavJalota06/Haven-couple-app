import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../couple_connection/bloc/couple_bloc.dart';
import '../../couple_connection/bloc/couple_state.dart';
import '../models/memory_model.dart';
import '../repositories/memories_repository.dart';
import 'add_memory_screen.dart';

class MemoriesTimelineScreen extends StatefulWidget {
  const MemoriesTimelineScreen({super.key});

  @override
  State<MemoriesTimelineScreen> createState() => _MemoriesTimelineScreenState();
}

class _MemoriesTimelineScreenState extends State<MemoriesTimelineScreen> {
  final _memoriesRepository = MemoriesRepository();
  final Set<String> _favoriteIds = {};

  void _toggleFavorite(String memoryId) {
    setState(() {
      if (_favoriteIds.contains(memoryId)) {
        _favoriteIds.remove(memoryId);
      } else {
        _favoriteIds.add(memoryId);
      }
    });
  }

  void _showMemoryDetailsSheet(BuildContext context, MemoryModel memory) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(memory.memoryDate);
    final isFav = _favoriteIds.contains(memory.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 20,
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
                const SizedBox(height: 14),

                // Top row with Category and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.champagne.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        memory.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.champagneDark,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _favoriteIds.contains(memory.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: AppColors.roseDust,
                            size: 24,
                          ),
                          onPressed: () {
                            _toggleFavorite(memory.id);
                            setModalState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Memory Title
                Text(
                  memory.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                // Date & Location Info Row
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),

                if (memory.locationName != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.roseDust),
                      const SizedBox(width: 6),
                      Text(
                        memory.locationName!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.roseDust,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Photos Gallery
                if (memory.mediaUrls.isNotEmpty) ...[
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: memory.mediaUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          memory.mediaUrls[i],
                          width: 240,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 240,
                            height: 200,
                            color: Colors.grey.shade900,
                            child: const Icon(Icons.photo_rounded, color: Colors.white30, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Full Story Description
                if (memory.description != null && memory.description!.isNotEmpty) ...[
                  const Text(
                    'Memory Narrative',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      memory.description!,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action buttons: Relive / Share, Delete
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.champagne,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Relive in Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Memory "${memory.title}" shared to your couple chat! 💌'),
                              backgroundColor: AppColors.champagneDark,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      tooltip: 'Delete memory',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _memoriesRepository.deleteMemory(memory.id);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Memory removed from timeline 🗑️')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CoupleBloc, CoupleState>(
      builder: (context, coupleState) {
        final relationship = (coupleState is CouplePaired) ? coupleState.relationship : null;

        if (relationship == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Shared Memories', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_border_rounded, size: 54, color: AppColors.champagne),
                    const SizedBox(height: 16),
                    const Text(
                      'No memories yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pair with your partner to start capturing your precious moments and building your timeline together.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Shared Memories', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                tooltip: 'Add Memory',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddMemoryScreen()),
                  );
                  setState(() {});
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<List<MemoryModel>>(
            stream: _memoriesRepository.getMemoriesStream(relationship.id),
            builder: (context, snapshot) {
              final memories = snapshot.data ?? _memoriesRepository.localMemories;

              if (memories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 54, color: AppColors.champagne),
                      const SizedBox(height: 16),
                      const Text(
                        'No memories saved yet.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Capture your beautiful milestones together.',
                        style: TextStyle(color: AppColors.textTertiaryDark),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.champagne, foregroundColor: Colors.black),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AddMemoryScreen()),
                          );
                          setState(() {});
                        },
                        icon: const Icon(Icons.add_a_photo_rounded),
                        label: const Text('Add First Memory'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: memories.length,
                itemBuilder: (context, index) {
                  final memory = memories[index];
                  final formattedDate = DateFormat('MMMM d, yyyy').format(memory.memoryDate);
                  final isFav = _favoriteIds.contains(memory.id);

                  return InkWell(
                    onTap: () => _showMemoryDetailsSheet(context, memory),
                    borderRadius: BorderRadius.circular(16),
                    child: GlassCard(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Badge & Favorite Button & Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.champagne.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  memory.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: AppColors.champagneDark,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _toggleFavorite(memory.id),
                                    child: Icon(
                                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      size: 18,
                                      color: isFav ? AppColors.roseDust : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Title
                          Text(
                            memory.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          if (memory.description != null && memory.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              memory.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                height: 1.4,
                              ),
                            ),
                          ],

                          // Thumbnail photo strip
                          if (memory.mediaUrls.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                memory.mediaUrls.first,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ],

                          if (memory.locationName != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.roseDust),
                                const SizedBox(width: 4),
                                Text(
                                  memory.locationName!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.roseDust,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1, end: 0);
                },
              );
            },
          ),
        );
      },
    );
  }
}
