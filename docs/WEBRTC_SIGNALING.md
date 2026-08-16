# Haven - WebRTC Realtime Audio & Video Calling Architecture

## 1. Overview

Haven implements direct peer-to-peer audio and video calling between two partners with WebRTC, STUN/TURN fallback servers, and Supabase Realtime broadcast channels for sub-second signaling.

```
+------------------+                                  +------------------+
| Partner A Device |                                  | Partner B Device |
+--------+---------+                                  +--------+---------+
         |                                                     |
         | 1. Join Broadcast Channel ('couple_call_signals')  |
         |---------------------------------------------------->|
         |                                                     |
         | 2. SDP Offer Broadcast                              |
         |====================================================>|
         |                                                     |
         | 3. SDP Answer Broadcast                             |
         |<====================================================|
         |                                                     |
         | 4. ICE Candidates Exchange                          |
         |<--------------------------------------------------->|
         |                                                     |
         | 5. Direct WebRTC P2P Media Stream (SRTP/DTLS)       |
         |<<<<<<<<<<<<<<<<<<<<=============================>>>>|
```

## 2. Signaling Events

Signals are dispatched over Supabase Realtime broadcast channels (`couple_call_signals_<relationshipId>`):

1. `offer`: Sent by the call initiator containing SDP offer description.
2. `answer`: Sent by recipient after accepting the call with SDP answer description.
3. `ice-candidate`: Dispatched as network interfaces and candidates are discovered.
4. `bye`: Hangup signal triggered when either party ends the call.

## 3. STUN/TURN Configuration

Standard STUN servers (Google STUN) resolve direct NAT mappings. In restrictive network environments (carrier NATs, firewalls), TURN servers relay encrypted SRTP packets securely.

```dart
final Map<String, dynamic> iceServers = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {
      'urls': 'turn:your-turn-server.com:3478',
      'username': 'haven_client',
      'credential': 'haven_turn_password',
    }
  ],
  'sdpSemantics': 'unified-plan',
};
```
