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
- Idea: exempt only address-family mismatches from badConnection in
  dkgsession.cpp.
- Status (Oct 2026): spork active since Aug 29, ten IPv6 masternodes
  registered and valid, but not yet checked whether any are running in
  quorums. No evidence of the problem yet. Get a real case first, by
  watching an active IPv6 node or reproducing on testnet, before
  writing code.

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
