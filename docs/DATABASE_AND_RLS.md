# Haven - Database Architecture & Row Level Security (RLS) Specification

## 1. Relational Schema Overview

Haven utilizes a normalized PostgreSQL database schema on Supabase configured with sound constraints, foreign keys, and indexes for real-time querying.

```
                    +-----------------------+
                    |    auth.users (JWT)   |
                    +-----------+-----------+
                                |
                                v
                    +-----------------------+
                    |    public.profiles    |
                    +-----------+-----------+
                                |
                   +------------+------------+
                   |                         |
                   v                         v
        +---------------------+   +---------------------+
        |  user1 (Creator)    |   |  user2 (Partner)    |
        +----------+----------+   +----------+----------+
                   |                         |
                   +------------+------------+
                                |
                                v
                    +-----------------------+
                    |  public.relationships |
                    +-----------+-----------+
                                |
     +--------------------------+--------------------------+
     |                          |                          |
     v                          v                          v
+---------------+       +---------------+          +---------------+
|   messages    |       |     calls     |          |  vault_items  |
+---------------+       +---------------+          +---------------+
|   memories    |       |  date_plans   |          | shared_goals  |
+---------------+       +---------------+          +---------------+
```

## 2. Table Definitions

| Table | Purpose | Security Level |
|---|---|---|
| `profiles` | User identity, display names, avatars, mood tags | Self + Connected Partner |
| `relationships` | Defines 2-user pairing, invite codes, anniversary | Relationship participants only |
| `messages` | Chat messages (text, media, voice, replies, pinned) | Relationship partners only |
| `message_receipts` | Delivered and read indicators | Relationship partners only |
| `message_reactions` | Emoji reactions per message | Relationship partners only |
| `calls` | Call session metadata, duration, call type | Relationship partners only |
| `call_signals` | WebRTC ICE and SDP exchange | Relationship partners only |
| `vault_items` | Client-side encrypted notes, photos, voice recordings | Relationship partners only |
| `memories` | Shared timeline, milestone stories, photo albums | Relationship partners only |
| `date_plans` | Date itineraries, budgets, and checklists | Relationship partners only |
| `bucket_list` | Lifetime shared experiences and goals | Relationship partners only |
| `shared_goals` | Financial and personal targets with progress | Relationship partners only |
| `love_notes` | Instant & time-locked love letters | Sender + Partner (after unlock) |
| `game_sessions` | Interactive couples game turn states & scores | Relationship partners only |
| `devices` | Device tokens for privacy-first push notifications | User only |

## 3. Row Level Security (RLS) & Anti-IDOR Enforcement

All 15 tables have RLS explicitly enabled (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`).

### Security Barrier Function

```sql
CREATE OR REPLACE FUNCTION public.is_relationship_partner(rel_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.relationships
        WHERE id = rel_id
        AND (user1_id = auth.uid() OR user2_id = auth.uid())
    );
$$;
```

### Protection Guarantees
1. **Zero Cross-Tenant Leakage**: A user cannot read, insert, update, or delete any record in another couple's relationship.
2. **Server-Enforced User Identity**: In all inserts, `auth.uid()` is verified against the `sender_id`, `created_by`, or `owner_id`.
3. **Time-Locked Authorization**: For `love_notes`, recipient read access is blocked until `unlock_at <= NOW()`.
