import Foundation

/// A capability a wallet provider may or may not support. Core uses the capability set to
/// resolve a provider for a feature (`providers(matching:)`) and to degrade gracefully where
/// a provider can't do something at all, rather than crashing.
///
/// The set a provider advertises should match the optional capability protocols it conforms to
/// (e.g. `.typedDataSigning` ⇔ `RainTypedDataSignerProvider`). The protocol conformance is what
/// actually dispatches; the capability is the declarative, queryable mirror of it.
public enum Capability: String, Sendable, Hashable, CaseIterable {
  /// EIP-712 typed-data signing (`RainTypedDataSignerProvider`). Required for withdrawals.
  case typedDataSigning
  /// Gas/fee estimation (`RainTransactionFeeEstimatingProvider`).
  case feeEstimation
  /// Native SOL + SPL token transfers (`RainSolanaTransfersProvider`).
  case solanaTransfers
  /// Private-key export.
  case export
  /// Account recovery.
  case recovery
  /// More than one chain family (e.g. EVM + Solana).
  case multiChain
  /// Signing gated behind a device biometric prompt.
  case biometricGate
}
