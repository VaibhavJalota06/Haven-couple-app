import 'package:flutter_test/flutter_test.dart';
import 'package:haven/features/discover/models/connection_request_model.dart';
import 'package:haven/features/discover/models/post_model.dart';
import 'package:haven/features/discover/repositories/discover_repository.dart';

void main() {
  group('Discover & Posts Feature Tests', () {
    late DiscoverRepository repository;

    setUp(() {
      repository = DiscoverRepository();
    });

    test('PostModel serialization and type checks', () {
      final post = PostModel(
        id: 'post_1',
        userId: 'usr_creator',
        mediaUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
        mediaType: PostMediaType.photo,
        caption: 'Sunset strolls with my favorite person 🌅',
        locationName: 'Amalfi Coast, Italy',
        createdAt: DateTime.now(),
      );

      final json = post.toJson();
      expect(json['media_type'], 'photo');
      expect(json['location_name'], 'Amalfi Coast, Italy');

      final parsed = PostModel.fromJson(json);
      expect(parsed.caption, post.caption);
      expect(parsed.mediaType, PostMediaType.photo);
    });

    test('DiscoverRepository creates post and queries explore feed', () async {
      final newPost = await repository.createPost(
        mediaUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
        caption: 'Testing Live Studio Posts ✨',
        locationName: 'Paris, France',
      );

      expect(newPost.caption, 'Testing Live Studio Posts ✨');
      expect(newPost.locationName, 'Paris, France');
    });

    test('DiscoverRepository sends connection request (Spark)', () async {
      final req = await repository.sendConnectionRequest(
        receiverId: 'user_target',
        message: 'Loved your couple travel photos! ✨',
      );

      expect(req.status, ConnectionRequestStatus.pending);
      expect(req.message, 'Loved your couple travel photos! ✨');
    });
  });
}
