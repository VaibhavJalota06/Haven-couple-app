import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';
import '../models/memory_model.dart';

class MemoriesRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  MemoriesRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  final List<MemoryModel> _localMemories = [
    MemoryModel(
      id: 'demo_m1',
      relationshipId: 'demo_couple_space',
      authorId: 'auth_id',
      title: 'First Trip to the Coast',
      description: 'Watching the golden sunset over the Pacific horizon and listening to the waves crash against the cliffs.',
      memoryDate: DateTime(2026, 7, 17),
      locationName: 'Sunset Cliffs, San Diego',
      category: 'First Trip',
      mediaUrls: const [
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
        'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=800&q=80',
      ],
      isFavorite: true,
      createdAt: DateTime(2026, 7, 17),
    ),
    MemoryModel(
      id: 'demo_m2',
      relationshipId: 'demo_couple_space',
      authorId: 'auth_id',
      title: 'The Day We Met',
      description: 'Sparks flew across the coffee shop table over warm cappuccinos. We talked for 4 hours non-stop.',
      memoryDate: DateTime(2023, 6, 15),
      locationName: 'Little Bean Roastery',
      category: 'Anniversary',
      mediaUrls: const [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&q=80',
        'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=800&q=80',
      ],
      isFavorite: true,
      createdAt: DateTime(2023, 6, 15),
    ),
    MemoryModel(
      id: 'demo_m3',
      relationshipId: 'demo_couple_space',
      authorId: 'auth_id',
      title: 'Starry Night Camping in Yosemite',
      description: 'Campfire under a million stars, sharing secrets and laughing until 3 AM.',
      memoryDate: DateTime(2024, 9, 22),
      locationName: 'Yosemite Valley, CA',
      category: 'Adventures',
      mediaUrls: const [
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80',
      ],
      isFavorite: false,
      createdAt: DateTime(2024, 9, 22),
    ),
  ];

  List<MemoryModel> get localMemories => List.unmodifiable(_localMemories);

  /// Stream or fetch memories chronologically
  Stream<List<MemoryModel>> getMemoriesStream(String relationshipId) async* {
    yield _localMemories;
    try {
      final stream = _client
          .from('memories')
          .stream(primaryKey: ['id'])
          .eq('relationship_id', relationshipId)
          .order('memory_date', ascending: false)
          .map((data) {
            final remote = data.map((json) => MemoryModel.fromJson(json)).toList();
            return remote.isNotEmpty ? remote : _localMemories;
          });
      yield* stream;
    } catch (_) {
      yield _localMemories;
    }
  }

  /// Create a shared memory
  Future<MemoryModel> createMemory({
    required String relationshipId,
    required String title,
    String? description,
    required DateTime memoryDate,
    String? locationName,
    List<File> imageFiles = const [],
    String category = 'general',
  }) async {
    final userId = currentUserId ?? 'current_user';
    final List<String> uploadedUrls = [];

    // Fallback aesthetic photos if none picked
    if (imageFiles.isEmpty) {
      uploadedUrls.add('https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=800&q=80');
    }

    // Upload memory images if any
    for (var file in imageFiles) {
      try {
        final fileExt = file.path.split('.').last;
        final fileName = '$relationshipId/memories/${_uuid.v4()}.$fileExt';
        await _client.storage.from(AppConstants.memoriesBucket).upload(fileName, file);
        final url = _client.storage.from(AppConstants.memoriesBucket).getPublicUrl(fileName);
        uploadedUrls.add(url);
      } catch (_) {
        uploadedUrls.add('https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=800&q=80');
      }
    }

    final newMemory = MemoryModel(
      id: _uuid.v4(),
      relationshipId: relationshipId,
      authorId: userId,
      title: title,
      description: description,
      memoryDate: memoryDate,
      locationName: locationName,
      mediaUrls: uploadedUrls,
      category: category,
      createdAt: DateTime.now(),
    );

    _localMemories.insert(0, newMemory);

    try {
      await _client.from('memories').insert(newMemory.toJson()).timeout(const Duration(seconds: 8));
    } catch (_) {}

    return newMemory;
  }

  /// Update memory
  Future<void> updateMemory(MemoryModel updated) async {
    final index = _localMemories.indexWhere((m) => m.id == updated.id);
    if (index != -1) {
      _localMemories[index] = updated;
    }
    try {
      await _client.from('memories').update(updated.toJson()).eq('id', updated.id).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// Delete memory
  Future<void> deleteMemory(String id) async {
    _localMemories.removeWhere((m) => m.id == id);
    try {
      await _client.from('memories').delete().eq('id', id).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
