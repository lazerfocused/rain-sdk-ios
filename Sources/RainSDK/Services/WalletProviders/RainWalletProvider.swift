import Foundation

/// Abstraction for a wallet/signer used for address, balance, transfers, and signing.
/// Implementations: Turnkey (core), Portal (`RainPortal`), Privy (`RainPrivy`), or other providers.
public protocol RainWalletProvider: Sendable {
  /// Stable identifier used to resolve this provider from the registry (`provider(_:)`).
  var id: ProviderID { get }

  /// The capabilities this provider supports. Mirrors the optional capability protocols the
  /// provider conforms to; used by `providers(matching:)` and for graceful degradation.
  var capabilities: Set<Capability> { get }

  /// Returns the wallet address for the given chain.
  func address(
  ) async throws -> String

  /// Chain-aware wallet address. Defaults to `address()`; providers that manage more than one
  /// address family (e.g. Turnkey resolving a Solana account for Solana chains) override it.
  func getAddress(chainId: Int) async throws -> String

  /// Sends a transaction; returns the transaction hash.
  func sendTransaction(
    chainId: Int,
    params: WalletTransactionParams
  ) async throws -> String

  /// Fetches a single balance (native or a contract token) as a rich `Balance`.
  /// - Parameters:
  ///   - chainId: The target blockchain network identifier.
  ///   - token: `.native` or a `.contract(address:)`.
  /// - Returns: A `Balance` with exact `rawAmount` plus resolved decimals / symbol / name.
  /// - Throws: RainSDKError if wallet is unavailable or the request fails.
  func getBalance(
    chainId: Int,
    token: Token
  ) async throws -> Balance

  /// Fetches all non-zero balances for the current wallet on the given network.
  /// - Parameter chainId: The target blockchain network identifier.
  /// - Returns: One `Balance` per non-zero token plus the native balance (always included).
  /// - Throws: RainSDKError if wallet is unavailable or the request fails.
  func getBalances(
    chainId: Int
  ) async throws -> [Balance]

  /// Fetches transaction history for the current wallet on the given network.
  /// - Parameters:
  ///   - chainId: The target blockchain network identifier.
  ///   - limit: Optional maximum number of transactions to return.
  ///   - offset: Optional offset for pagination.
  ///   - order: Optional sort order (e.g. newest first).
  /// - Returns: List of high-level `WalletTransaction` records.
  /// - Throws: RainSDKError if wallet is unavailable or the request fails.
  func getTransactions(
    chainId: Int,
    limit: Int?,
    offset: Int?,
    order: WalletTransactionOrder?
  ) async throws -> [WalletTransaction]
}

public extension RainWalletProvider {
  /// EVM-only providers inherit the single-address behaviour.
  func getAddress(chainId: Int) async throws -> String {
    try await address()
  }
}

