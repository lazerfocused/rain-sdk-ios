import Testing
import Foundation
@testable import RainPortal
@_spi(RainAdapters) @testable import RainSDK

@Suite("Portal Initialization Tests")
struct PortalInitializationTests {
  @Test("initializePortal throws unauthorized for empty token")
  func testEmptyToken() async throws {
    let manager = RainSDKManager()
    await #expect(throws: RainSDKError.unauthorized) {
      try await manager.initializePortal(portalSessionToken: "", networkConfigs: [NetworkConfig.testConfig(chainId: 1)])
    }
  }

  @Test("initializePortal throws invalidConfig for zero chain ID")
  func testInvalidChainIdZero() async throws {
    let manager = RainSDKManager()
    await #expect(throws: RainSDKError.invalidConfig(chainId: 0, rpcUrl: "https://test-rpc.com")) {
      try await manager.initializePortal(portalSessionToken: "test-token", networkConfigs: [NetworkConfig.testConfig(chainId: 0)])
    }
  }

  @Test("initializePortal throws invalidConfig for empty RPC URL")
  func testEmptyRpcUrl() async throws {
    let manager = RainSDKManager()
    await #expect(throws: RainSDKError.invalidConfig(chainId: 1, rpcUrl: "")) {
      try await manager.initializePortal(portalSessionToken: "test-token", networkConfigs: [NetworkConfig.testConfig(chainId: 1, rpcUrl: "")])
    }
  }

  @Test("initializePortal throws invalidConfig for non-HTTP scheme")
  func testRpcUrlNonHttpScheme() async throws {
    let manager = RainSDKManager()
    await #expect(throws: RainSDKError.invalidConfig(chainId: 1, rpcUrl: "ftp://example.com")) {
      try await manager.initializePortal(portalSessionToken: "test-token", networkConfigs: [NetworkConfig.testConfig(chainId: 1, rpcUrl: "ftp://example.com")])
    }
  }
}
