# Rain iOS Modular Provider Split — Design

**Date:** 2026-06-21
**Status:** Approved design, pre-implementation
**Source:** `docs/rain-sdk-modular-architecture.html` (Ports & Adapters proposal)

## Goal

Split the monolithic `RainSDK` iOS package so wallet providers live in their own
distributable modules and a client links only what it uses. Honor the proposal's
ports-and-adapters thesis while adopting a product decision specific to iOS:

- **Turnkey is the baseline.** It ships *with* core (Rain's CST/session backbone).
- **Portal and Privy are separate packages.** A client adds them only when needed.

## Decisions (locked)

1. **Topology — Turnkey in core.** `rain-core` carries the Turnkey adapter and the
   Turnkey `swift-sdk` dependency. Portal/Privy are separate packages that depend on
   core; a Portal-only app therefore also resolves Turnkey (accepted — Turnkey is the
   baseline auth/session provider, not an optional wallet).
2. **Privy scope — scaffold + stub.** Create the `RainPrivy` package and a
   `PrivyProvider` conforming to the port whose methods throw `notImplemented`. No real
   Privy SDK dependency yet. Proves "a new provider costs existing clients nothing."
3. **Portal back-compat — clean break + migration note.** The core `RainSDK` protocol
   drops `var portal` and `initializePortal`. Portal integrators add `import RainPortal`
   and use RainPortal's `initializePortal`. Turnkey/base clients are unchanged. No core
   umbrella shim (it would re-introduce the PortalSwift dependency for everyone).
4. **Never commit without explicit ask** (project CLAUDE.md). This spec is written, not
   committed.

## Package topology

Three packages, one dev repo. Sub-packages wired via local `.package(path:)`; later
extractable to their own git repos (`rain-portal-ios`, `rain-privy-ios`) for publishing.
A single `swift build` / `swift test` works locally throughout.

```
rain-sdk-ios/                      (git repo)
  Package.swift                    module RainSDK   — core + Turnkey (deps: Turnkey, web3, web3swift, QRCode)
  Sources/RainSDK/...
  Packages/
    RainPortal/Package.swift       module RainPortal — dep path(../..) RainSDK + PortalSwift
    RainPortal/Sources/RainPortal/...
    RainPortal/Tests/...
    RainPrivy/Package.swift        module RainPrivy  — dep path(../..) RainSDK (Privy SDK: later)
    RainPrivy/Sources/RainPrivy/...
```

Consumer graphs:
- Turnkey / base app: `RainSDK` (Turnkey present).
- Portal app: `RainPortal` → transitively `RainSDK` (+ Turnkey) + PortalSwift.
- Privy app: `RainPrivy` → transitively `RainSDK` (+ Turnkey) + Privy.

## Registry + capability model (proposal §04/05)

Add to core (module `RainSDK`):

```swift
public enum ProviderID: String, Sendable, Hashable {
  case turnkey, portal, privy
}

public enum Capability: Sendable, Hashable {
  case typedDataSigning   // RainTypedDataSignerProvider
  case feeEstimation      // RainTransactionFeeEstimatingProvider
  case solanaTransfers    // RainSolanaTransfersProvider
  case export, recovery, multiChain, biometricGate
}
```

Extend the existing port:

```swift
public protocol RainWalletProvider: Sendable {
  var id: ProviderID { get }
  var capabilities: Set<Capability> { get }
  // ... existing: address(), getAddress(chainId:), sendTransaction, getBalance(s),
  //               getTransactions(...)
}
```

Registry on `RainSDKManager` (N-provider design; single provider is N=1):

```swift
public func register(_ provider: any RainWalletProvider)          // adds + sets active
public func provider(_ id: ProviderID) throws -> any RainWalletProvider
public func providers(matching capability: Capability) -> [any RainWalletProvider]
```

`setWalletProvider(_:)` stays as back-compat (registers + sets active). The active
provider continues to back `_walletProvider` so existing call sites are unchanged.

## What moves to RainPortal

From core into `Packages/RainPortal/Sources/RainPortal/`:

| Item | Today | After |
|------|-------|-------|
| `PortalWalletProviderAdapter.swift` | core | RainPortal |
| `PortalProviderResult+Hex.swift` | core | RainPortal |
| `Protocols/PortalProtocol.swift` (`PortalRequestProtocol`) | core | RainPortal |
| Portal branches of `RainSDKError+Mapping` | core | RainPortal `RainSDKError+Portal.swift` |
| `WalletTransaction.init(_ tx: FetchedTransaction)` | core model | RainPortal extension |
| `WalletTransactionOrder.toPortalOrder` | core model | RainPortal extension |
| `composeTransactionParameters` (returns `ETHTransactionParam`) | core `Deprecated.swift` | RainPortal extension |

New in RainPortal:
- `public final class PortalProvider: RainWalletProvider, RainTypedDataSignerProvider,
  RainTransactionFeeEstimatingProvider` — `id = .portal`, capabilities
  `[.typedDataSigning, .feeEstimation, .multiChain]`. Wraps the moved adapter logic and
  exposes the underlying `Portal` (`public var portal: Portal`) for clients that need it.
- `public extension RainSDKManager { func initializePortal(portalSessionToken:networkConfigs:) async throws }`
  — built only on core's **public** API: `try await initialize(networkConfigs:)` then
  `register(PortalProvider(...))`. `PortalProvider` builds its own `EVMChainReader` /
  `TokenMetadataStore` / `TransactionBuilderService` from the network configs.

To make that possible, core must expose as `public` (with public initializers) the
services a provider needs to construct itself: `EVMChainReader`, `TokenMetadataStore`,
`TransactionBuilderService` (and `TransactionBuilderProtocol`). These are currently
`internal`. Widening them is the price of an out-of-package adapter; they remain Rain
domain types (no vendor leakage).

## Hexagonal cleanup (sever vendor coupling in core)

- **Errors at the boundary.** Each adapter maps its own vendor errors to `RainSDKError`
  inside the adapter, so only `RainSDKError` escapes a provider. Core's
  `RainSDKError.from(underlying:)` keeps generic (`RainSDKError` passthrough, NSURLError,
  ASAuthorization cancel) + Turnkey branches, and never imports `PortalSwift`. The Portal
  mapping moves to RainPortal and is invoked by `PortalProvider`/the adapter.
- **Vendor-free shared models.** `WalletTransaction` and `WalletTransactionOrder` drop
  `import PortalSwift`; their Portal mappings become RainPortal extensions. The structs
  already expose public memberwise initializers, so RainPortal can build them.
- **Manager.** `RainSDKManager` drops `_portal`, `portal`, `portalProtocol`,
  `portalForRequest`, `initializePortal`, and Portal-only helpers (`validateInputs`,
  `buildRpcConfig`). `RainSDK` protocol drops `var portal` and `initializePortal`.

## Breaking change (Portal integrators only)

```swift
// before
import RainSDK
try await manager.initializePortal(portalSessionToken: token, networkConfigs: configs)
let portal = try manager.portal

// after
import RainSDK
import RainPortal
try await manager.initializePortal(portalSessionToken: token, networkConfigs: configs) // from RainPortal
// hold the Portal instance you constructed (or read PortalProvider.portal)
```

Turnkey and wallet-agnostic clients: **no change.** README gets a migration note; the
proposal §09 migration skill is future work.

## RainPrivy (scaffold)

`Packages/RainPrivy/` depends on `RainSDK` only. `PrivyProvider: RainWalletProvider`
with `id = .privy`, an embedded-key-oriented capability set, and every method throwing
`RainSDKError.notImplemented`. Add `RainSDKError.notImplemented` to core. No Privy SDK
dependency in this pass.

## Tests

- **Stay in core:** Turnkey adapter/Solana tests, ChainReader, TokenStore, manager API
  (non-Portal), error mapping (generic + Turnkey), Solana, deprecated (non-Portal).
- **Move to `Packages/RainPortal/Tests/`:** `PortalAdapterTests`, `MockPortal`,
  Portal-specific init cases, Portal error-mapping cases, `composeTransactionParameters`.
- **New:** registry tests (register/resolve by id + capability) in core; a RainPortal
  test asserting `PortalProvider` wires correctly via `setWalletProvider`/`register`.
- Each build step keeps the whole workspace green.

## Example app

Add a local `RainPortal` package reference; update Portal wiring (`import RainPortal`,
RainPortal's `initializePortal`, read `Portal` from the host-held instance /
`PortalProvider.portal`). Turnkey demo paths unchanged.

## Build sequence (each step compiles + tests green)

1. **Registry/capability in core** — add `ProviderID`, `Capability`, port `id`/
   `capabilities`, manager registry; give existing Turnkey + (still-in-core) Portal
   adapters their `id`/`capabilities`. Non-breaking, still a monolith.
2. **Push Portal mapping to the adapter boundary** — Portal error mapping + the
   `WalletTransaction`/`WalletTransactionOrder` Portal mappings relocate behind the
   adapter; core shared files stop needing them. Still one package.
3. **Make core services public** — `EVMChainReader`, `TokenMetadataStore`,
   `TransactionBuilderService(+Protocol)` gain public inits.
4. **Extract `RainPortal`** — create the package, move Portal files, add `PortalProvider`
   + `initializePortal` extension, strip Portal from core (`RainSDK` protocol + manager +
   Package.swift). Move Portal tests. Core now builds Turnkey-only. **Breaking for Portal
   clients.**
5. **Scaffold `RainPrivy`** — package + stub `PrivyProvider` + `notImplemented`.
6. **Docs/migration** — README migration note, METHODS update, compatibility matrix.

## Out of scope (this pass)

- CocoaPods subspecs (proposal §06) — SPM first.
- BOM / compatibility-matrix tooling (proposal §08) beyond a doc note.
- The automated migration skill (proposal §09).
- Real Privy integration; splitting sub-packages into their own git repos.

## Risks

- **Out-of-package adapter needs core services public.** Mitigated: only Rain domain
  services widen to public; no vendor types leak.
- **Portal break.** Accepted per decision 3; scoped to Portal integrators; documented.
- **SPM local-path dev vs published-repo URLs.** Dev uses `path:`; publishing later
  swaps to versioned URLs. Note in README.
