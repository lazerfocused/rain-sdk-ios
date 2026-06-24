# Rain SDK iOS

[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen)](#installation)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-not--supported-lightgrey)](#installation)
[![Carthage](https://img.shields.io/badge/Carthage-not--supported-lightgrey)](#installation)

iOS SDK with first-class [Portal](https://portalhq.io) and [Turnkey](https://www.turnkey.com) wallet support: build EIP-712 messages, compose withdrawal transactions, sign and submit through the active wallet provider, and estimate fees.

## Features

- **Portal wallet integration** — Initialize with a Portal session token and network configs; use the connected wallet for signing and sending transactions.
- **Turnkey wallet integration** — Initialize with an authenticated Turnkey context and network configs; use the selected Turnkey wallet for signing and sending transactions.
- **Wallet-agnostic mode** — Initialize with network configs only (no wallet provider) to use transaction-building APIs (EIP-712 message, withdraw calldata, composed params) with your own wallet or backend.
- **EIP-712 message building** — Build typed data for admin signature required by the collateral contract.
- **Withdrawal transaction building** — Build ABI-encoded withdraw calldata and compose `ETHTransactionParam` for submission.
- **Full withdrawal flow** — builds the transaction, signs via the active wallet provider, and submits; returns the transaction hash.
- **Fee estimation** — returns the estimated gas cost in the chain’s native token (e.g. ETH).
- **Wallet information** — get current wallet address and generate a QR code image (PNG) for it.
- **Balances** — get native and ERC-20 token balances for the current wallet.
- **Transaction history** — get transactions for the current wallet with optional pagination and sort order (`WalletTransaction`, `WalletTransactionOrder`).
- **Send tokens** — send native or ERC-20 tokens from the current wallet.

## Modular packages

The SDK follows a ports-and-adapters layout so a client links only the wallet providers it uses:

| Module | Contains | Vendor pulled in |
|--------|----------|------------------|
| **RainSDK** (rain-core) | Rain domain (CST auth, collateral, tx orchestration, balances), the `RainWalletProvider` port, the provider registry, **and the Turnkey adapter** (Turnkey is the baseline) | Turnkey |
| **RainPortal** | Portal wallet adapter (`PortalProvider`, `initializePortal`) | + PortalSwift |
| **RainPrivy** | Privy wallet adapter (scaffold) | + Privy (later) |

- A Turnkey / base app links **RainSDK** only.
- A Portal app links **RainPortal** (which pulls RainSDK transitively, so Turnkey is also present).
- Adapters self-register at runtime via `RainSDKManager.register(_:)`; resolve by id with
  `manager.provider(.portal)` or by capability with `manager.providers(matching: .typedDataSigning)`.

## Installation

### Swift Package Manager

Add the package(s) you need (Xcode: **File → Add Package Dependencies**):

```
https://github.com/SignifyHQ/rain-sdk-ios          # RainSDK (core + Turnkey)
https://github.com/SignifyHQ/rain-portal-ios        # RainPortal (Portal)
```

During development the provider packages live under `Packages/` and reference rain-core by local
path; published they become their own versioned repos. Then add the **RainSDK** product (and
**RainPortal** if you use Portal) to your target.

> **Migrating from the monolithic 1.x?** Portal moved out of the core module. Add the
> **RainPortal** package and `import RainPortal`; `initializePortal(...)` now comes from RainPortal.
> The call site is otherwise unchanged. The old `manager.portal` accessor is gone — read the Portal
> instance from the provider instead: `try (manager.provider(.portal) as? PortalProvider)?.portal`.
> Turnkey and wallet-agnostic integrations need no changes.

## Requirements

- iOS 17.0+
- Swift 6.1+
- Xcode 15.0+

## Usage

### 1. Initialize with Portal (full wallet flow)

Use this when you want the SDK to use Portal for signing and sending transactions.

```swift
import RainSDK
import RainPortal   // Portal lives in its own package

let manager = RainSDKManager()

let networkConfigs = [
    NetworkConfig(chainId: 1, rpcUrl: "https://mainnet.infura.io/v3/YOUR_KEY"),
    NetworkConfig(chainId: 137, rpcUrl: "https://polygon-rpc.com")
]

try await manager.initializePortal(   // from RainPortal
    portalSessionToken: "<your-portal-session-token>",
    networkConfigs: networkConfigs
)

// Access the Portal instance when needed (e.g. for UI)
let portal = try (manager.provider(.portal) as? PortalProvider)?.portal
```

### 2. Initialize with Turnkey (full wallet flow)

Use this when you want the SDK to use Turnkey for signing and sending transactions.

Authenticate with the official Turnkey Swift SDK first, for example using auth proxy middleware and
passkeys:

- Proxy middleware: `https://docs.turnkey.com/sdks/swift/proxy-middleware`
- Passkeys: `https://docs.turnkey.com/sdks/swift/register-passkey`

Then pass the authenticated `TurnkeyContext` into Rain:

```swift
import RainSDK
import TurnkeySwift

let manager = RainSDKManager()

try await manager.initializeTurnkey(
    turnkey: turnkeyContext,
    networkConfigs: networkConfigs,
    walletAddress: nil // optional explicit EVM address override
)

let turnkey = try manager.turnkey
```

### 3. Initialize without a wallet provider (wallet-agnostic)

Use this when you only need transaction building (EIP-712 message, calldata, composed params) and will sign or submit elsewhere.

```swift
let manager = RainSDKManager()

try await manager.initialize(networkConfigs: networkConfigs)

// buildEIP712Message, buildWithdrawTransactionData, composeTransactionParameters
// are available; withdrawCollateral requires a wallet provider that supports
// EIP-712 signing, transaction submission, and fee estimation.
```

### 4. Read balances

Balances are returned as rich `Balance` values that carry the exact base-unit `rawAmount`
(a `BigUInt`, never lossy) alongside resolved `decimals`/`symbol`/`name` and convenience
`decimalAmount` / `formatted` accessors. A `Token` is either `.native` or `.contract(address:)`.

```swift
// A single balance (native or a specific token):
let eth = try await manager.getBalance(chainId: 1, token: .native)
let usdc = try await manager.getBalance(
    chainId: 1,
    token: .contract(address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
)
print(usdc.formatted)       // e.g. "1.5"
print(usdc.rawAmount)       // exact base units, e.g. 1500000

// Every non-zero balance on a chain (native is always included):
let balances = try await manager.getBalances(chainId: 1)

// Every balance across all configured chains, flattened (each Balance carries its chainId):
let all = try await manager.getAllBalances()
```

Token metadata for well-known tokens is built in. To resolve a token the SDK doesn't know
about without an on-chain `decimals()` / `symbol()` lookup, register it up front:

```swift
manager.registerTokens([
    TokenInfo(chainId: 1, address: "0x…", symbol: "FOO", decimals: 18, name: "Foo Token")
])
```

Unregistered contract tokens are still resolved automatically by reading `decimals()` /
`symbol()` on-chain once, then cached.

For a short overview of all public methods, see [Method overview](docs/METHODS.md).

## License

See the [LICENSE](LICENSE) file for details.
