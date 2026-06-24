import Foundation
import PortalSwift
import RainSDK

public extension RainSDKManager {
  /// Initializes the SDK with a Portal session token and network configurations.
  ///
  /// Builds a `Portal` instance, wraps it in a `PortalProvider`, and registers it as the active
  /// wallet provider. Use the Turnkey path (`initializeTurnkey`) or `initialize` for other modes.
  ///
  /// - Parameters:
  ///   - portalSessionToken: A valid Portal session token.
  ///   - networkConfigs: Network configurations (chain ID + RPC URL) for the chains to support.
  /// - Throws: `RainSDKError` if the token is empty, the configs are invalid, or Portal fails to
  ///   initialize.
  func initializePortal(
    portalSessionToken: String,
    networkConfigs: [NetworkConfig]
  ) async throws {
    guard !portalSessionToken.isEmpty else {
      throw RainSDKError.unauthorized
    }

    // Wallet-agnostic base: validates configs and sets up the transaction builder.
    try await initialize(networkConfigs: networkConfigs)

    do {
      let rpcConfig = portalRpcConfig(from: networkConfigs)
      let portal = try Portal(
        portalSessionToken,
        withRpcConfig: rpcConfig,
        autoApprove: true,
        iCloud: ICloudStorage(),
        keychain: PortalKeychain(),
        passwords: PasswordStorage()
      )
      register(PortalProvider(portal: portal, networkConfigs: networkConfigs))
    } catch let error as RainSDKError {
      throw error
    } catch {
      throw RainSDKError.fromPortal(error)
    }
  }

  /// Builds Portal's EIP-155 RPC endpoint map (e.g. `["eip155:1": "https://…"]`) from the configs.
  private func portalRpcConfig(from networkConfigs: [NetworkConfig]) -> [String: String] {
    var config: [String: String] = [:]
    for networkConfig in networkConfigs {
      config[networkConfig.eip155ChainId] = networkConfig.rpcUrl
    }
    return config
  }
}

public extension RainSDK {
  /// Deprecated alias for ``buildTransactionParameters(walletAddress:contractAddress:transactionData:)``.
  @available(*, deprecated, message: "Renamed to buildTransactionParameters, which returns Rain-owned RainTransactionParameters. This shim adapts to Portal's ETHTransactionParam.")
  func composeTransactionParameters(walletAddress: String, contractAddress: String, transactionData: String) -> ETHTransactionParam {
    let p = buildTransactionParameters(walletAddress: walletAddress, contractAddress: contractAddress, transactionData: transactionData)
    return ETHTransactionParam(from: p.from, to: p.to, value: p.value, data: p.data)
  }
}
