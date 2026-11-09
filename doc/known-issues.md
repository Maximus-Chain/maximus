# Known Issues / Future Work

Running list of deferred items and follow-up projects. Not blocking
any release.

## Next release plan (no binaries planned before next year)

Order matters: one risky change at a time, so any problem found in
soak-testing can be traced to a single cause.

### Phase 1 - low-risk changes (done, shipping in 1.2.4)
- PROTOCOL_VERSION 70231 -> 70232 in src/version.h.
  MIN_PEER_PROTO_VERSION is left alone in this release.
- Backport of the Dash v23.1.7 DKG security fixes: pushed DKG messages
  are accepted only from verified masternodes, their size is bounded,
  their structure is validated before they are retained, and the
  null-pointer dereference for a missing verification vector is fixed.
- Status: implemented on branch phase1-dkg-hardening and checked with
  the repo's LLMQ functional tests. A mixed-version soak on testnet is
  the next step.

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
  registered address family differs from ours and we have no connected
  peer in that family. A dual-stack node that can reach the family
  keeps the normal checks. Keep the minimum protocol version check as
  it is.
- Limits: it only helps once most nodes have upgraded, since old nodes
  still complain. It does not create connectivity, so a dual-stack
  member must relay between the two families. A really offline member
  is still caught because it sends no contribution; only the pure
  connection check is skipped for members we cannot reach. Making
  quorum connections and relay members address-family aware is a
  larger change and is left for the DKG restructure.
- Status (Nov 2026): spork active since Aug 29, ten IPv6 masternodes
  registered and valid, not confirmed running in quorums. Not yet
  reproduced on a live network. Test on testnet with a mix of
  IPv4-only and IPv6 members.

### Phase 3 - version gating and connection pacing
- Release N ships PROTOCOL_VERSION 70232.
- Release N+1, once adoption is high, raises MIN_PEER_PROTO_VERSION to
  70232. Never both in one release, there is no spork safety valve.
- Lower urgency now: adoption of v1.2.3 is about 100%.
- Also in this phase: connection-burst pacing in net.cpp (100ms ->
  250ms post-connect sleep). Not implemented yet. Test on testnet
  before it ships.

## Later
- Full Dash DKG restructure (llmq/ + active/ split, static AddLLMQ()
  instead of UpdateLLMQParams). Do after Phase 2 is proven. Carry the
  IPv6 logic across at that point.
- InstantSend performance backport from Dash v23.1.0.
- CMake migration, then Qt6. Dash has done neither (Qt 5.15.18).
- native_clang is pinned at 10.0.1. Aim for Clang 16-17 if upgrading.
- Post-quantum cryptography. No Bitcoin or Dash plan exists yet.
