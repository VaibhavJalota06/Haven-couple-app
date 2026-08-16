import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/models/user_profile.dart';
import '../models/connection_request_model.dart';
import '../models/post_model.dart';

class DiscoverRepository {
  static final DiscoverRepository _instance = DiscoverRepository._internal();
  factory DiscoverRepository({SupabaseClient? client}) => _instance;

  final SupabaseClient _client;
  final List<ConnectionRequestModel> _localRequests = [];

  // Persistent Spark Status tracking across the entire app
  final Map<String, ConnectionRequestStatus> _sparkStatuses = {};

  // Broadcast stream for realtime spark events (sent, accepted, notifications)
  final StreamController<Map<String, dynamic>> _sparkStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get sparkUpdates => _sparkStreamController.stream;

  DiscoverRepository._internal({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Get persistent spark status for any user (none, pending, accepted, declined)
  ConnectionRequestStatus getSparkStatus(String userId) {
    return _sparkStatuses[userId] ?? ConnectionRequestStatus.none;
  }

  /// Helper to get user profile by ID
  UserProfile? getUserById(String userId) {
    try {
      return demoUsers.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  /// Send a spark to a user - updates persistent state, locks chat, and triggers acceptance
  Future<void> sendSpark(String userId, {String? message, bool simulateAcceptance = true}) async {
    _sparkStatuses[userId] = ConnectionRequestStatus.pending;
    _sparkStreamController.add({
      'type': 'spark_sent',
      'userId': userId,
      'status': ConnectionRequestStatus.pending,
      'user': getUserById(userId),
    });

    try {
      await sendConnectionRequest(receiverId: userId, message: message);
    } catch (_) {}

    if (simulateAcceptance) {
      // Realistic simulation: partner accepts request after 3.5 seconds
      Timer(const Duration(milliseconds: 3500), () {
        if (_sparkStatuses[userId] == ConnectionRequestStatus.pending) {
          acceptSpark(userId, triggerNotification: true);
        }
      });
    }
  }

  /// Accept a spark connection - unlocks messaging and sends notification event
  void acceptSpark(String userId, {bool triggerNotification = true}) {
    _sparkStatuses[userId] = ConnectionRequestStatus.accepted;
    _sparkStreamController.add({
      'type': 'spark_accepted',
      'userId': userId,
      'status': ConnectionRequestStatus.accepted,
      'user': getUserById(userId),
      'triggerNotification': triggerNotification,
    });
  }

  /// Reset or cancel spark
  void resetSpark(String userId) {
    _sparkStatuses[userId] = ConnectionRequestStatus.none;
    _sparkStreamController.add({
      'type': 'spark_reset',
      'userId': userId,
      'status': ConnectionRequestStatus.none,
      'user': getUserById(userId),
    });
  }

  /// Seed discoverable users with aesthetic photo & reel portfolios
  static final List<UserProfile> demoUsers = [
    UserProfile(
      id: 'demo_user_1',
      email: 'elena@haven.app',
      fullName: 'Elena Rostova',
      nickname: 'Elena',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&q=80',
      mood: 'adventurous',
      moodEmoji: '✨',
      isOnline: true,
      createdAt: DateTime(2023, 8, 12),
    ),
    UserProfile(
      id: 'demo_user_2',
      email: 'liam@haven.app',
      fullName: 'Liam Thorne',
      nickname: 'Liam',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&q=80',
      mood: 'chill',
      moodEmoji: '☕',
      isOnline: false,
      createdAt: DateTime(2023, 9, 20),
    ),
    UserProfile(
      id: 'demo_user_3',
      email: 'sophia@haven.app',
      fullName: 'Sophia Laurent',
      nickname: 'Sophia',
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&q=80',
      mood: 'creative',
      moodEmoji: '🎨',
      isOnline: true,
      createdAt: DateTime(2023, 10, 5),
    ),
    UserProfile(
      id: 'demo_user_4',
      email: 'alex@haven.app',
      fullName: 'Alex Rivera',
      nickname: 'Alex',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&q=80',
      mood: 'wanderlust',
      moodEmoji: '🌿',
      isOnline: true,
      createdAt: DateTime(2023, 11, 1),
    ),
  ];

  static final List<PostModel> demoPosts = [
    PostModel(
      id: 'p1',
      userId: 'demo_user_1',
      userFullName: 'Elena Rostova',
      userAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&q=80',
      mediaUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&q=80',
      caption: 'Sunset in Amalfi Coast 🌅 Always finding new horizons.',
      locationName: 'Positano, Italy',
      mediaType: PostMediaType.photo,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    PostModel(
      id: 'p2',
      userId: 'demo_user_1',
      userFullName: 'Elena Rostova',
      userAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&q=80',
      mediaUrl: 'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=800&q=80',
      caption: 'Little moments in Kyoto 🍵',
      locationName: 'Kyoto, Japan',
      mediaType: PostMediaType.reel,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PostModel(
      id: 'p3',
      userId: 'demo_user_3',
      userFullName: 'Sophia Laurent',
      userAvatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&q=80',
      mediaUrl: 'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?w=800&q=80',
      caption: 'Weekend architectural sketches & jazz ☕',
      locationName: 'Paris, France',
      mediaType: PostMediaType.photo,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    PostModel(
      id: 'p4',
      userId: 'demo_user_2',
      userFullName: 'Liam Thorne',
      userAvatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&q=80',
      mediaUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80',
      caption: 'Morning hike through Yosemite Valley 🏔️',
      locationName: 'Yosemite, California',
      mediaType: PostMediaType.photo,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PostModel(
      id: 'p5',
      userId: 'demo_user_4',
      userFullName: 'Alex Rivera',
      userAvatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&q=80',
      mediaUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800&q=80',
      caption: 'Film photography in the alpine forest 🌲',
      locationName: 'Banff, Canada',
      mediaType: PostMediaType.reel,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    PostModel(
      id: 'p6',
      userId: 'demo_user_3',
      userFullName: 'Sophia Laurent',
      userAvatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&q=80',
      mediaUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&q=80',
      caption: 'Finding calm in rooftop gardens 🌿',
      locationName: 'Montmartre, Paris',
      mediaType: PostMediaType.photo,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  List<PostModel>? _cachedExploreFeed;
  final Map<String, List<PostModel>> _portfolioCache = {};

  /// Get explore feed of posts & reels (Instant in-memory cache + fast timeout)
  Future<List<PostModel>> getExploreFeed() async {
    if (_cachedExploreFeed != null && _cachedExploreFeed!.isNotEmpty) {
      return _cachedExploreFeed!;
    }

    try {
      final data = await _client
          .from('posts')
          .select('*, profiles(full_name, avatar_url)')
          .order('created_at', ascending: false)
          .limit(30)
          .timeout(const Duration(seconds: 8));

      if (data.isNotEmpty) {
        _cachedExploreFeed = (data as List).map((json) => PostModel.fromJson(json)).toList();
        return _cachedExploreFeed!;
      }
    } catch (_) {}

    _cachedExploreFeed = demoPosts;
    return _cachedExploreFeed!;
  }

  /// Get a specific user's portfolio posts (Instant cache + fast timeout)
  Future<List<PostModel>> getUserPortfolio(String userId) async {
    if (_portfolioCache.containsKey(userId) && _portfolioCache[userId]!.isNotEmpty) {
      return _portfolioCache[userId]!;
    }

    try {
      final data = await _client
          .from('posts')
          .select('*, profiles(full_name, avatar_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));

      if (data.isNotEmpty) {
        final posts = (data as List).map((json) => PostModel.fromJson(json)).toList();
        _portfolioCache[userId] = posts;
        return posts;
      }
    } catch (_) {}

    final posts = demoPosts.where((p) => p.userId == userId).toList();
    _portfolioCache[userId] = posts.isNotEmpty ? posts : demoPosts.take(3).toList();
    return _portfolioCache[userId]!;
  }

  /// Search discoverable users (Instant in-memory filter + fast remote timeout)
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return demoUsers;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .ilike('full_name', '%${query.trim()}%')
          .limit(20)
          .timeout(const Duration(seconds: 8));

      if (data.isNotEmpty) {
        return (data as List).map((json) => UserProfile.fromJson(json)).toList();
      }
    } catch (_) {}

    return demoUsers
        .where((u) => u.fullName.toLowerCase().contains(query.toLowerCase()) || (u.nickname?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();
  }

  /// Send a connection request (Follow / Couple Handshake)
  Future<ConnectionRequestModel> sendConnectionRequest({
    required String receiverId,
    String? message,
  }) async {
    final senderId = currentUserId ?? 'current_user';

    try {
      final payload = {
        'id': const Uuid().v4(),
        'sender_id': senderId,
        'receiver_id': receiverId,
        'status': 'pending',
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      };

      final data = await _client.from('connection_requests').insert(payload).select().single();
      return ConnectionRequestModel.fromJson(data);
    } catch (_) {
      final req = ConnectionRequestModel(
        id: 'local_req_${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        status: ConnectionRequestStatus.pending,
        createdAt: DateTime.now(),
      );
      _localRequests.add(req);
      return req;
    }
  }

  /// Get pending incoming connection requests
  Future<List<ConnectionRequestModel>> getIncomingRequests() async {
    final userId = currentUserId;
    if (userId != null) {
      try {
        final data = await _client
            .from('connection_requests')
            .select('*, profiles!sender_id(*)')
            .eq('receiver_id', userId)
            .eq('status', 'pending')
            .order('created_at', ascending: false);

        if (data.isNotEmpty) {
          return (data as List).map((json) {
            UserProfile? sender;
            if (json['profiles'] != null) {
              sender = UserProfile.fromJson(json['profiles']);
            }
            return ConnectionRequestModel.fromJson(json, sender: sender);
          }).toList();
        }
      } catch (_) {}
    }

    // Default incoming request for demo testing
    return [
      ConnectionRequestModel(
        id: 'req_demo_elena',
        senderId: 'demo_user_1',
        receiverId: userId ?? 'current_user',
        status: ConnectionRequestStatus.pending,
        message: 'Loved your travel portfolio! Would love to connect ✨',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        senderProfile: demoUsers.first,
      ),
    ];
  }

  /// Accept incoming connection request and lock into a 2-person Haven Couple
  Future<Map<String, dynamic>> acceptRequest(String requestId) async {
    try {
      final response = await _client.rpc(
        'accept_connection_request',
        params: {'p_request_id': requestId},
      );
      return response as Map<String, dynamic>;
    } catch (_) {
      return {
        'success': true,
        'relationship_id': 'rel_connected_${DateTime.now().millisecondsSinceEpoch}',
      };
    }
  }

  /// Create a new post / reel
  Future<PostModel> createPost({
    required String mediaUrl,
    String? thumbnailUrl,
    PostMediaType mediaType = PostMediaType.photo,
    String? caption,
    String? locationName,
  }) async {
    final userId = currentUserId ?? 'current_user';
    final newId = const Uuid().v4();
    final payload = {
      'id': newId,
      'user_id': userId,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'media_type': mediaType == PostMediaType.reel ? 'reel' : 'photo',
      'caption': caption,
      'location_name': locationName,
      'created_at': DateTime.now().toIso8601String(),
    };

    final newPost = PostModel(
      id: newId,
      userId: userId,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      mediaType: mediaType,
      caption: caption,
      locationName: locationName,
      createdAt: DateTime.now(),
    );

    try {
      final res = await _client.from('posts').insert(payload).select().single().timeout(const Duration(seconds: 8));
      return PostModel.fromJson(res);
    } catch (_) {
      return newPost;
    }
  }
}
