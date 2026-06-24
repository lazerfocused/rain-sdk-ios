import Testing
import Foundation
@testable import RainSDK

@Suite("SDK Initialization Tests")
struct SDKInitializationTests {

  // MARK: - Provider access before init

  @Test("turnkey access before initialization throws sdkNotInitialized")
  func testTurnkeyAccessBeforeInitialization() throws {
    let manager = RainSDKManager()

    #expect(throws: RainSDKError.sdkNotInitialized) {
      try manager.turnkey
    }
  }

  // MARK: - Wallet-agnostic initialize

  @Test("initialize succeeds with valid configs")
  func testInitializeSuccess() async throws {
    let manager = RainSDKManager()
    let configs = [
      NetworkConfig.testConfig(chainId: 1, rpcUrl: "https://mainnet.infura.io/v3/test"),
      NetworkConfig.testConfig(chainId: 137, rpcUrl: "https://polygon-rpc.com")
    ]

    try await manager.initialize(networkConfigs: configs)
  }

  @Test("initialize throws invalidConfig for empty configs")
  func testInitializeEmptyConfigs() async throws {
    let manager = RainSDKManager()

    await #expect(throws: RainSDKError.invalidConfig(chainId: 0, rpcUrl: "")) {
      try await manager.initialize(networkConfigs: [])
    }
  }

  @Test("initialize throws invalidConfig for zero chain ID")
  func testInitializeInvalidChainIdZero() async throws {
    let manager = RainSDKManager()
    let configs = [NetworkConfig.testConfig(chainId: 0)]

    await #expect(throws: RainSDKError.invalidConfig(chainId: 0, rpcUrl: "https://test-rpc.com")) {
      try await manager.initialize(networkConfigs: configs)
    }
  }

  @Test("initialize throws invalidConfig for empty RPC URL")
  func testInitializeEmptyRpcUrl() async throws {
    let manager = RainSDKManager()
    let configs = [NetworkConfig.testConfig(chainId: 1, rpcUrl: "")]

    await #expect(throws: RainSDKError.invalidConfig(chainId: 1, rpcUrl: "")) {
      try await manager.initialize(networkConfigs: configs)
    }
  }

  @Test("initialize throws invalidConfig for URL without scheme")
  func testInitializeRpcUrlMissingScheme() async throws {
    let manager = RainSDKManager()
    let configs = [NetworkConfig.testConfig(chainId: 1, rpcUrl: "not-a-valid-url")]

    await #expect(throws: RainSDKError.invalidConfig(chainId: 1, rpcUrl: "not-a-valid-url")) {
      try await manager.initialize(networkConfigs: configs)
    }
  }

  @Test("initialize throws invalidConfig for non-HTTP scheme")
  func testInitializeRpcUrlNonHttpScheme() async throws {
    let manager = RainSDKManager()
    let configs = [NetworkConfig.testConfig(chainId: 1, rpcUrl: "ftp://example.com")]

    await #expect(throws: RainSDKError.invalidConfig(chainId: 1, rpcUrl: "ftp://example.com")) {
      try await manager.initialize(networkConfigs: configs)
    }
  }

  // MARK: - Turnkey test seam

  @Test("Turnkey test initializer wires a Turnkey-backed wallet provider")
  func testTurnkeyInitializerSuccess() async throws {
    let (manager, _, _) = TestManagers.turnkeyManager()

    let walletAddress = try await manager.getWalletAddress()
    #expect(walletAddress == MockTurnkey.defaultWalletAddress)
  }
}
