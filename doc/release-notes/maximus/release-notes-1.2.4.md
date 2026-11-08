# Maximus Core version v1.2.4

Recommended update: network hardening and stability.

1.2.4 improves the stability and resilience of the network and of masternode
quorum formation. It is a recommended update for everyone, and especially for
masternode operators. It is compatible with 1.2.3 nodes, so the network keeps
working while operators upgrade at their own pace.

Please report bugs using the issue tracker at GitHub:

  <https://github.com/maximus-core/maximus/issues>


# Who should update

- Masternode operators: strongly recommended.
- Node operators, pools, exchanges and services: recommended. No action is
  required immediately, and nothing stops working on 1.2.3.


# What's new

## Network and masternodes

- Stricter validation of masternode quorum (DKG) messages: they are now only
  accepted from authenticated masternode peers, with size and structure checks
  before processing.
- Additional signature and input checks in the quorum code, plus a guard
  against malformed data in the BLS worker.
- Protocol version raised to 70232. The minimum supported peer protocol is
  unchanged, so 1.2.3 peers can still connect.
- General stability improvements.

## Build

- Builds with GCC 15 and Python 3.12+.
- Fixes for the gmp, xcb_proto/xproto, mimalloc and miniupnpc builds in
  depends and dashbls.
- New release build recipe for Ubuntu 22.04 and 26.04 in doc/build-unix.md.


# Upgrading

- Stop the node, replace the binaries with the 1.2.4 build, start again.
- No reindex or database change is needed.
- Masternodes: no re-registration, no collateral or key changes.
- This is a source release. Build instructions are in doc/build-unix.md.

Version: 1.2.4   Protocol: 70232


# Credits

Thanks to everyone who directly contributed to this release:

- realgreenminer.
