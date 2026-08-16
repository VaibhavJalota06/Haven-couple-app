# Vibe-Check Security Rules & Agent Guardrails
<!-- Generated according to benavlabs/vibe-check open-source framework -->

## 1. Authentication & Authorization (Broken Access Control & IDOR)
- **Profile Privacy**: Never allow a user to edit, mutate, or overwrite another user's profile details, avatar, or settings. All mutations must be scoped to `currentUser.id`.
- **Relationship Boundaries**: Data scoped to a relationship (messages, photos, memories, shared goals) must verify that the requesting user is either `user1_id` or `user2_id` of that relationship.
- **Visitor Isolation**: Public/Discover profile viewers must only have access to read-only visitor interactions (*Spark*, *Message*, *View highlights*). Edit actions, private toggle controls, and settings must be omitted entirely.

## 2. Secrets & Sensitive Data Management
- Never hardcode API secrets, service role keys, or private tokens in source code.
- Always load sensitive environment variables from `.env` or secure vault storage.
- Never commit `.env`, keystores (`.jks`, `.keystore`), or certificates (`.pem`, `.p12`) to git.

## 3. Cryptography & Vault Key Management
- End-to-End Encryption (E2EE) for private chat and vault memories must use standard **AES-256-GCM** with unique nonces/IVs per encryption operation.
- Key derivation from passphrases must use **PBKDF2** with SHA-256 and $\ge 100,000$ iterations.
- Vault master keys and App Lock PINs must be stored exclusively in platform secure storage (**`FlutterSecureStorage`** with `encryptedSharedPreferences` on Android and Keychain on iOS), never in plaintext `SharedPreferences`.

## 4. Input Validation & Bounds Checking
- Validate and sanitize all user input at UI boundaries:
  - Custom contribution amounts must be positive numbers with sane upper bounds.
  - Invite codes must be sanitized to uppercase alphanumeric characters.
  - Text fields must enforce maximum length constraints to prevent resource exhaustion.

## 5. Client-Side State & Memory Safety
- Clear sensitive state on user sign-out (`SecureStorageService`, local in-memory caches, and active controllers).
- Keep real-time subscriptions isolated to the user's active relationship room.
