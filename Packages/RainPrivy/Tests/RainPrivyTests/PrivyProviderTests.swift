import Testing
import Foundation
@testable import RainPrivy
import RainSDK

@Suite("Privy Provider Scaffold Tests")
struct PrivyProviderTests {

  @Test("id is .privy")
  func testId() {
    #expect(PrivyProvider().id == .privy)
  }

  @Test("address throws notImplemented")
  func testAddressNotImplemented() async {
    await #expect(throws: RainSDKError.notImplemented(method: "PrivyProvider.address")) {
      _ = try await PrivyProvider().address()
    }
  }

  @Test("sendTransaction throws notImplemented")
  func testSendTransactionNotImplemented() async {
    let params = WalletTransactionParams(from: "0x0", to: "0x0", value: "0x0", data: "0x")
    await #expect(throws: RainSDKError.self) {
      _ = try await PrivyProvider().sendTransaction(chainId: 1, params: params)
    }
  }

  @Test("can be registered and resolved by id")
  func testRegisterAndResolve() async throws {
    let manager = RainSDKManager()
    try await manager.initialize(networkConfigs: [NetworkConfig(chainId: 1, rpcUrl: "https://rpc.test")])
    manager.register(PrivyProvider())

    let resolved = try manager.provider(.privy)
    #expect(resolved.id == .privy)
  }
}
