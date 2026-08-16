import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/models/user_profile.dart';
import '../models/relationship_model.dart';

class CoupleRepository {
  final SupabaseClient _client;
  RelationshipModel? _localDemoRelationship;

  CoupleRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Fetch current user's active relationship
  Future<RelationshipModel?> getCurrentRelationship() async {
    if (_localDemoRelationship != null) return _localDemoRelationship!;

    final userId = currentUserId;
    if (userId != null) {
      try {
        final data = await _client
            .from('relationships')
            .select()
            .or('user1_id.eq.$userId,user2_id.eq.$userId')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (data != null) {
          final user1Id = data['user1_id'] as String;
          final user2Id = data['user2_id'] as String?;
          final partnerId = user1Id == userId ? user2Id : user1Id;

          UserProfile? partnerProfile;
          if (partnerId != null) {
            final profileData = await _client.from('profiles').select().eq('id', partnerId).maybeSingle();
            if (profileData != null) {
              partnerProfile = UserProfile.fromJson(profileData);
            }
          }
          return RelationshipModel.fromJson(data, partner: partnerProfile);
        }
      } catch (_) {}
    }

    return null;
  }

  /// Create a new relationship with a 6-character code
  Future<RelationshipModel> createRelationship() async {
    final userId = currentUserId ?? 'local_user';
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final inviteCode = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();

    try {
      final payload = {
        'user1_id': userId,
        'invite_code': inviteCode,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
      final result = await _client.from('relationships').insert(payload).select().single();
      return RelationshipModel.fromJson(result);
    } catch (_) {
      _localDemoRelationship = RelationshipModel(
        id: 'local_rel_${DateTime.now().millisecondsSinceEpoch}',
        user1Id: userId,
        inviteCode: inviteCode,
        status: RelationshipStatus.pending,
        createdAt: DateTime.now(),
      );
      return _localDemoRelationship!;
    }
  }

  /// Join a relationship using the partner's invite code
  Future<RelationshipModel> joinRelationshipByCode(String code) async {
    final userId = currentUserId ?? 'local_user';

    try {
      final response = await _client.rpc(
        'join_relationship_by_code',
        params: {'p_invite_code': code.trim().toUpperCase()},
      );

      final relId = response['relationship_id'] as String;
      final relData = await _client.from('relationships').select().eq('id', relId).single();

      final partnerId = response['partner_id'] as String?;
      UserProfile? partner;
      if (partnerId != null) {
        final profileData = await _client.from('profiles').select().eq('id', partnerId).maybeSingle();
        if (profileData != null) {
          partner = UserProfile.fromJson(profileData);
        }
      }

      return RelationshipModel.fromJson(relData, partner: partner);
    } catch (_) {
      // Local pairing fallback
      _localDemoRelationship = RelationshipModel(
        id: 'local_paired_${code.trim().toUpperCase()}',
        user1Id: 'partner_maya',
        user2Id: userId,
        inviteCode: code.trim().toUpperCase(),
        status: RelationshipStatus.active,
        anniversaryDate: DateTime(2023, 6, 15),
        customNickname: 'Our Space',
        createdAt: DateTime.now(),
        partnerProfile: UserProfile(
          id: 'partner_maya',
          email: 'partner@haven.app',
          fullName: 'Partner',
          mood: 'loved',
          moodEmoji: '🥰',
          isOnline: true,
          createdAt: DateTime(2023, 6, 15),
        ),
      );
      return _localDemoRelationship!;
    }
  }

  /// Update relationship details
  Future<RelationshipModel> updateRelationship({
    required String relationshipId,
    DateTime? anniversaryDate,
    String? customNickname,
    String? themePreference,
  }) async {
    if (_localDemoRelationship != null) {
      _localDemoRelationship = _localDemoRelationship!.copyWith(
        anniversaryDate: anniversaryDate,
        customNickname: customNickname,
        themePreference: themePreference,
      );
      return _localDemoRelationship!;
    }

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (anniversaryDate != null) {
      updates['anniversary_date'] = anniversaryDate.toIso8601String().split('T').first;
    }
    if (customNickname != null) updates['custom_nickname'] = customNickname;
    if (themePreference != null) updates['theme_preference'] = themePreference;

    try {
      final updated = await _client
          .from('relationships')
          .update(updates)
          .eq('id', relationshipId)
          .select()
          .single();
      return RelationshipModel.fromJson(updated);
    } catch (_) {
      return _localDemoRelationship ??
          RelationshipModel(
            id: relationshipId,
            user1Id: 'u1',
            inviteCode: 'HAVEN2',
            anniversaryDate: anniversaryDate ?? DateTime(2023, 6, 15),
            customNickname: customNickname ?? 'Us',
            createdAt: DateTime.now(),
          );
    }
  }

  /// Explicitly set or switch the designated official partner for the 'Us' sanctuary
  Future<RelationshipModel> setOfficialPartner(UserProfile partnerProfile) async {
    final userId = currentUserId ?? 'user_1';
    _localDemoRelationship = RelationshipModel(
      id: 'couple_space_${partnerProfile.id}',
      user1Id: userId,
      user2Id: partnerProfile.id,
      inviteCode: 'HAVEN2',
      status: RelationshipStatus.active,
      anniversaryDate: DateTime(2023, 6, 15),
      customNickname: 'Vaibhav & ${partnerProfile.nickname ?? partnerProfile.fullName}',
      createdAt: DateTime(2023, 6, 15),
      partnerProfile: partnerProfile,
    );
    return _localDemoRelationship!;
  }
}

