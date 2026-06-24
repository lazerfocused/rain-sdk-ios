import Foundation

/// Sort order for transaction history (e.g. in `getTransactions(chainId:limit:offset:order:)`).
/// Provider-agnostic; mapped to each provider's order type (e.g. Portal's `TransactionOrder`)
/// inside that provider's adapter.
public enum WalletTransactionOrder: String, Codable, Sendable {
  case ASC
  case DESC
}
