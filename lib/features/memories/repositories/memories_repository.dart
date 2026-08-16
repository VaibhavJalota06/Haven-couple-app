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

  final List<MemoryModel> _localMemories = [];

  List<MemoryModel> get localMemories => List.unmodifiable(_localMemories);

  /// Stream or fetch memories chronologically
  Stream<List<MemoryModel>> getMemoriesStream(String relationshipId) async* {
    yield _localMemories;
    if (relationshipId.isNotEmpty) {
      try {
        final stream = _client
            .from('memories')
            .stream(primaryKey: ['id'])
            .eq('relationship_id', relationshipId)
            .order('memory_date', ascending: false)
            .map((data) {
              final remote = data.map((json) => MemoryModel.fromJson(json)).toList();
              _localMemories.clear();
              _localMemories.addAll(remote);
              return _localMemories;
            });
        yield* stream;
      } catch (_) {
        yield _localMemories;
      }
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
