import 'package:flutter_test/flutter_test.dart';
import 'package:haven/features/memories/models/memory_model.dart';
import 'package:haven/features/memories/repositories/memories_repository.dart';

void main() {
  group('Memories Feature Tests', () {
    late MemoriesRepository repository;

    setUp(() {
      repository = MemoriesRepository();
    });

    test('MemoryModel serialization and media list management', () {
      final memory = MemoryModel(
        id: 'mem_1',
        relationshipId: 'rel_test',
        authorId: 'usr_1',
        title: 'Road Trip to Big Sur 🚗',
        description: 'Coastal drives and ocean breeze',
        memoryDate: DateTime(2025, 5, 20),
        mediaUrls: const [
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
        ],
        isFavorite: true,
        createdAt: DateTime.now(),
      );

      final json = memory.toJson();
      expect(json['title'], 'Road Trip to Big Sur 🚗');
      expect(json['media_urls'], isA<List>());

      final deserialized = MemoryModel.fromJson(json);
      expect(deserialized.title, memory.title);
      expect(deserialized.isFavorite, true);
    });

    test('MemoriesRepository creates and updates memory', () async {
      final newMem = await repository.createMemory(
        relationshipId: 'rel_test',
        title: 'First Date Coffee Shop',
        description: 'The moment everything began ❤️',
        memoryDate: DateTime(2023, 6, 15),
      );

      expect(newMem.title, 'First Date Coffee Shop');
      final updated = newMem.copyWith(isFavorite: true);
      await repository.updateMemory(updated);

      expect(repository.localMemories.firstWhere((m) => m.id == newMem.id).isFavorite, true);
    });
  });
}
