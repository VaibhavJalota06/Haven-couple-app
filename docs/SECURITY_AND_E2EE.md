# Haven - Security, Cryptography & Privacy Specification

## 1. Core Principles

1. **Privacy First**: No public social graph, no ad tracking, no data monetization.
2. **Two People Only**: Strict mathematical and database boundary guaranteeing two-person isolation.
3. **Defense in Depth**: Combination of Supabase Row Level Security (RLS) + Client-Side AES-256-GCM Encryption + Biometric App Lock.

## 2. Cryptographic Architecture

Haven uses industry standard, audited cryptographic primitives provided by the `cryptography` package:

- **Symmetric Encryption**: AES-GCM with 256-bit keys (`AesGcm.with256Bits()`)
- **Key Derivation**: PBKDF2 with HMAC-SHA256 (`Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 100000, bits: 256)`)
- **Nonce & Auth Tag**: 96-bit random nonce with 128-bit GCM MAC verification tag.
- **Hardware Key Storage**: Keys stored on-device using Android Keystore (`EncryptedSharedPreferences`) and iOS Keychain (`KeychainAccessibility.first_unlock`).

```
+------------------------------------------------------------------------+
|                            Device Key Storage                          |
|  [Android Keystore / iOS Keychain] -> Master Vault Secret Key (256-bit)|
+-----------------------------------+------------------------------------+
                                    |
                                    v
+------------------------------------------------------------------------+
|                          AES-256-GCM Encryption                        |
|  Plaintext + SecretKey + Nonce -> Ciphertext + 128-bit Auth Tag        |
+-----------------------------------+------------------------------------+
                                    |
                                    v
+------------------------------------------------------------------------+
|                       Supabase Encrypted Storage                       |
|  Encrypted payload stored in PostgreSQL 'vault_items' & 'love_notes'   |
+------------------------------------------------------------------------+
```

## 3. Threat Model & Protections

| Threat | Mitigation in Haven |
|---|---|
| Insecure Direct Object Reference (IDOR) | Postgres RLS enforces `is_relationship_partner(rel_id)` on every operation |
| Compromised Database Server | Vault payloads & secret notes are AES-GCM encrypted on-device |
| Device Theft | Biometric App Lock (`local_auth`) with auto-lock timer & fallback PIN |
| Shoulder Surfing & App Switcher | App screenshot obscuring & optional notification preview masking |
| Man-in-the-Middle (MITM) | TLS 1.3 for all Supabase HTTPS/WSS endpoints + DTLS-SRTP for WebRTC |
