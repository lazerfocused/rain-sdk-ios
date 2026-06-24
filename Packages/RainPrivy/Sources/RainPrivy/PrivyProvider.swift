import Foundation
import RainSDK

/// Privy embedded-key wallet provider.
///
/// **Scaffold.** This module proves the modular architecture: a brand-new provider arrives as its
/// own package with its own (eventual) vendor dependency, costing existing clients nothing. The
/// provider conforms to the core `RainWalletProvider` port and self-registers like any other —
/// `manager.register(PrivyProvider())` — but every operation currently throws
/// `RainSDKError.notImplemented` until the Privy embedded-key SDK is integrated. There is no Privy
/// SDK dependency in this package yet.
public final class PrivyProvider: RainWalletProvider, @unchecked Sendable {
  public let id: ProviderID = .privy

  /// Empty until the integration lands. The embedded-key capability set (e.g. `.export`,
  /// `.recovery`, `.typedDataSigning`) will be declared here once each is actually backed by an
  /// implementation and the matching capability protocol is adopted.
  public let capabilities: Set<Capability> = []

  public init() {}

  public func address() async throws -> String {
    throw RainSDKError.notImplemented(method: "PrivyProvider.address")
  }

  public func sendTransaction(
    chainId: Int,
    params: WalletTransactionParams
  ) async throws -> String {
    throw RainSDKError.notImplemented(method: "PrivyProvider.sendTransaction")
  }

  public func getBalance(
    chainId: Int,
    token: Token
  ) async throws -> Balance {
    throw RainSDKError.notImplemented(method: "PrivyProvider.getBalance")
  }

  public func getBalances(
    chainId: Int
  ) async throws -> [Balance] {
    throw RainSDKError.notImplemented(method: "PrivyProvider.getBalances")
  }

  public func getTransactions(
    chainId: Int,
    limit: Int?,
    offset: Int?,
    order: WalletTransactionOrder?
  ) async throws -> [WalletTransaction] {
    throw RainSDKError.notImplemented(method: "PrivyProvider.getTransactions")
  }
}
