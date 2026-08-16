# Haven - Your Private Digital Home for Two

> **“A production-quality cross-platform couples space combining private chat, WebRTC video calling, shared memories, date planning, and a biometric vault.”**

---

## 🌟 Philosophy & Architecture

Haven is engineered from the ground up specifically for two people in a relationship:
- **No Public Social Network**: Zero followers, feeds, or external discovery.
- **Privacy First**: Strict PostgreSQL Row Level Security (RLS), on-device biometric lock, and AES-256-GCM encrypted private vault.
- **Warm & Luxury Aesthetic**: Deep Obsidian Charcoal, Rose Gold Champagne, and warm tactile micro-interactions.

---

## 📱 Feature Highlights

1. **Us Dashboard**: Realtime partner presence, days together milestone counter, anniversary countdown, live mood tags, and quick action drawers.
2. **Private Chat**: Realtime messaging with Supabase channels, read/delivered receipts, audio voice notes, photo/video sharing, replies, emoji reactions, and scheduled messages.
3. **Audio & Video Calling**: Direct peer-to-peer WebRTC calling with STUN/TURN fallback and Supabase Realtime broadcast signaling.
4. **Together Mode & Games**: Synchronized couple games (*Would You Rather*, *Truth or Dare*, *Couple Trivia*), shared drawing canvas, and synchronized media room.
5. **Private Encrypted Vault**: Biometric & PIN protected vault with client-side AES-256-GCM encryption for sensitive notes, photos, and voice memos.
6. **Shared Memories**: Chronological timeline of relationship milestones, stories, and photo albums.
7. **Date Planner & Shared Goals**: Shared date itineraries, collaborative bucket lists, and savings/personal goal progress trackers.
8. **Privacy Center**: Encryption key management, active session management, notification preview hiding, and account deletion controls.

---

## 🗄️ Supabase Backend Structure

- **Migrations (`supabase/migrations/`)**:
  - `01_initial_schema.sql`: Normalized tables (`profiles`, `relationships`, `messages`, `calls`, `vault_items`, `memories`, `date_plans`, `bucket_list`, `shared_goals`, `love_notes`, `game_sessions`, `devices`).
  - `02_rls_policies.sql`: Strict Row Level Security policies preventing cross-relationship access and IDOR exploits.
  - `03_storage_buckets.sql`: Storage buckets (`avatars`, `chat_media`, `memories`, `vault_media`) with couple isolation rules.
  - `04_functions_and_triggers.sql`: Stored procedures for invite code pairing, updated_at timestamps, and realtime publications.

---

## 🚀 Getting Started

1. Set up your Supabase project using the SQL files in `supabase/migrations/`.
2. Configure `.env` with your Supabase URL and public anonymous key.
3. Run `flutter pub get` and `flutter run`.

---

## 🧪 Testing Suite

Run all automated unit and BLoC tests:
```bash
flutter test
```
Tests include:
- `test/core/security/encryption_service_test.dart`
- `test/features/auth/auth_bloc_test.dart`
- `test/features/couple_connection/couple_connection_test.dart`
- `test/features/chat/message_model_test.dart`
