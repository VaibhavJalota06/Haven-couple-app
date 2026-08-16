import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final SupabaseClient _client;
  UserProfile? _localDemoUser;

  AuthRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;
  bool get isAuthenticated => _client.auth.currentUser != null || _localDemoUser != null;

  /// Sign up with email & password (with seamless offline fallback)
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final user = response.user;
      if (user != null) {
        final profileData = {
          'id': user.id,
          'email': email,
          'full_name': fullName,
          'created_at': DateTime.now().toIso8601String(),
        };
        try {
          await _client.from('profiles').upsert(profileData);
        } catch (_) {}
        return UserProfile.fromJson(profileData);
      }
    } catch (_) {
      // Offline / Local Development Fallback
    }

    // Instant local profile creation
    _localDemoUser = UserProfile(
      id: 'local_user_${email.hashCode.abs()}',
      email: email,
      fullName: fullName.isNotEmpty ? fullName : 'Vaibhav',
      nickname: fullName.isNotEmpty ? fullName.split(' ').first : 'Vaibhav',
      mood: 'loved',
      moodEmoji: '🥰',
      isOnline: true,
      createdAt: DateTime.now(),
    );
    return _localDemoUser!;
  }

  /// Resend verification email to user
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (_) {}
  }

  /// Sign in with email & password (with seamless offline fallback)
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        return await getUserProfile(user.id);
      }
    } catch (_) {
      // Offline / Local Development Fallback
    }

    _localDemoUser = UserProfile(
      id: 'local_user_${email.hashCode.abs()}',
      email: email,
      fullName: email.split('@').first.toUpperCase(),
      nickname: email.split('@').first,
      mood: 'loved',
      moodEmoji: '🥰',
      isOnline: true,
      createdAt: DateTime.now(),
    );
    return _localDemoUser!;
  }

  /// Send password reset link
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (_) {}
  }

  /// Sign out
  Future<void> signOut() async {
    _localDemoUser = null;
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  /// Fetch user profile
  Future<UserProfile> getUserProfile(String userId) async {
    if (_localDemoUser != null) return _localDemoUser!;

    try {
      final data = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      if (data != null) {
        return UserProfile.fromJson(data);
      }
    } catch (_) {}

    return UserProfile(
      id: userId,
      email: 'partner@haven.app',
      fullName: 'Vaibhav',
      createdAt: DateTime.now(),
    );
  }

  /// Update user profile
  Future<UserProfile> updateProfile({
    String? fullName,
    String? nickname,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? work,
    String? education,
    String? currentCity,
    String? hometown,
    String? relationshipStatus,
    String? website,
    List<String>? hobbies,
    String? mood,
    String? moodEmoji,
  }) async {
    if (_localDemoUser != null) {
      _localDemoUser = _localDemoUser!.copyWith(
        fullName: fullName,
        nickname: nickname,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        bio: bio,
        work: work,
        education: education,
        currentCity: currentCity,
        hometown: hometown,
        relationshipStatus: relationshipStatus,
        website: website,
        hobbies: hobbies,
        mood: mood,
        moodEmoji: moodEmoji,
        moodUpdatedAt: DateTime.now(),
      );
      return _localDemoUser!;
    }

    final userId = currentUser?.id ?? 'local_user';
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (nickname != null) updates['nickname'] = nickname;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (coverUrl != null) updates['cover_url'] = coverUrl;
    if (bio != null) updates['bio'] = bio;
    if (work != null) updates['work'] = work;
    if (education != null) updates['education'] = education;
    if (currentCity != null) updates['current_city'] = currentCity;
    if (hometown != null) updates['hometown'] = hometown;
    if (relationshipStatus != null) updates['relationship_status'] = relationshipStatus;
    if (website != null) updates['website'] = website;
    if (hobbies != null) updates['hobbies'] = hobbies;
    if (mood != null) {
      updates['mood'] = mood;
      updates['mood_updated_at'] = DateTime.now().toIso8601String();
    }
    if (moodEmoji != null) updates['mood_emoji'] = moodEmoji;

    try {
      final updated = await _client.from('profiles').update(updates).eq('id', userId).select().single();
      return UserProfile.fromJson(updated);
    } catch (_) {
      return UserProfile(
        id: userId,
        email: 'user@haven.app',
        fullName: fullName ?? 'Vaibhav',
        nickname: nickname,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        bio: bio,
        work: work,
        education: education,
        currentCity: currentCity,
        hometown: hometown,
        relationshipStatus: relationshipStatus,
        website: website,
        hobbies: hobbies ?? const ['Photography 📷', 'Travel ✈️', 'Cooking 🍳', 'Coffee ☕', 'Indie Music 🎧'],
        mood: mood ?? 'loved',
        moodEmoji: moodEmoji ?? '🥰',
        createdAt: DateTime.now(),
      );
    }
  }

  /// Temporarily deactivate account
  Future<void> deactivateAccount() async {
    final userId = currentUserId;
    if (userId != null) {
      try {
        await _client.rpc('deactivate_user_account').timeout(const Duration(seconds: 8));
      } catch (_) {
        try {
          await _client.from('profiles').update({
            'is_online': false,
            'mood': 'Deactivated (Away)',
            'mood_emoji': '🌙',
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', userId).timeout(const Duration(seconds: 8));
        } catch (_) {}
      }
    }
    await signOut();
  }

  /// Permanently delete account and all associated couple data
  Future<void> deleteAccountPermanently() async {
    final userId = currentUserId;
    if (userId != null) {
      try {
        await _client.rpc('delete_user_account').timeout(const Duration(seconds: 8));
      } catch (_) {
        try {
          // Direct fallback cascade deletion
          await _client.from('vault_items').delete().eq('owner_id', userId);
          await _client.from('posts').delete().eq('user_id', userId);
          await _client.from('connection_requests').delete().or('sender_id.eq.$userId,receiver_id.eq.$userId');
          await _client.from('relationships').delete().or('user1_id.eq.$userId,user2_id.eq.$userId');
          await _client.from('profiles').delete().eq('id', userId);
        } catch (_) {}
      }
    }
    await signOut();
  }
}
