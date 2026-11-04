# Known Issues / Future Work

Running list of deferred items and follow-up projects. Not blocking
any release.

## Next release plan (no binaries planned before next year)

Order matters: one risky change at a time, so any problem found in
soak-testing can be traced to a single cause.

### Phase 1 - low-risk changes
- PROTOCOL_VERSION 70231 -> 70232 in src/version.h. No behavior change
  on its own. Leave MIN_PEER_PROTO_VERSION alone in this release.
- Backport Dash v23.1.7 DKG security fixes: accept pushed DKG messages
  only from verified masternodes, bound their size, validate structure
  before retaining, and fix the null-pointer dereference when a
  contribution share's verification vector was never received.
  Needs a real diff against Dash's fix before implementing.

### Phase 2 - IPv6 DKG fairness (custom work, Dash has no IPv6 support)
- Goal: an IPv4-only and an IPv6-only masternode should not punish each
  other in DKG when they structurally cannot connect. Offline nodes of
  any address family are still punished normally.
- Why it is needed: with SPORK_21 (all quorum members connected)
  active, a node that has no connection to a member marks it
  badConnection and complains about it, which leads to PoSe
  punishment. An IPv4-only node never connects to an IPv6-only member,
  so IPv6 masternodes would be punished. This follows from
  CDKGSession::VerifyConnectionAndMinProtoVersions, so the fix is
  needed before SPORK_21 can be fully on for IPv6 masternodes.
- Idea: in dkgsession.cpp, skip badConnection (both "not connected to
  us" and "failed to connect too many times") when the member's
  registered address family differs from ours. Keep the minimum
  protocol version check as it is.
- Limits: it only helps once most nodes have upgraded, since old nodes
  still complain. It does not create connectivity, so a dual-stack
  member must relay between the two families. Detection of really
  offline IPv6 nodes by IPv4 nodes gets weaker.
- Status (Nov 2026): spork active since Aug 29, ten IPv6 masternodes
  registered and valid, not confirmed running in quorums. Not yet
  reproduced on a live network. Test on testnet with a mix of
  IPv4-only and IPv6 members.

### Phase 3 - version gating (two releases)
- Release N ships PROTOCOL_VERSION 70232.
- Release N+1, once adoption is high, raises MIN_PEER_PROTO_VERSION to
  70232. Never both in one release, there is no spork safety valve.
- Lower urgency now: adoption of v1.2.3 is about 100%.

## Later
- Full Dash DKG restructure (llmq/ + active/ split, static AddLLMQ()
  instead of UpdateLLMQParams). Do after Phase 2 is proven. Carry the
  IPv6 logic across at that point.
- InstantSend performance backport from Dash v23.1.0.
- Connection-burst pacing in net.cpp (100ms -> 250ms post-connect
  sleep). Never implemented or tested.
- CMake migration, then Qt6. Dash has done neither (Qt 5.15.18).
- native_clang is pinned at 10.0.1. Aim for Clang 16-17 if upgrading.
- Post-quantum cryptography. No Bitcoin or Dash plan exists yet.
