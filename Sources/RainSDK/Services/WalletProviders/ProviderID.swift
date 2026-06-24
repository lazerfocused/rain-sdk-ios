import Foundation

/// Stable identifier for a wallet provider. The registry resolves providers by this id.
///
/// Turnkey ships with core (Rain's baseline session/signing provider). Portal and Privy
/// live in their own packages (`RainPortal`, `RainPrivy`) and self-register at runtime.
public enum ProviderID: String, Sendable, Hashable, CaseIterable {
  case turnkey
  case portal
  case privy
}
