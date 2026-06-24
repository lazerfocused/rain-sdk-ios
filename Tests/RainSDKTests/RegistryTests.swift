import Testing
import Foundation
@testable import RainSDK

/// Tests for the provider registry (ProviderID / Capability resolution) on RainSDKManager.
/// The registry is designed for N providers; a single-provider app is the trivial N = 1 case.
@Suite("Provider Registry Tests")
struct RegistryTests {

  @Test("register makes a provider resolvable by id")
  func testRegisterResolveById() async throws {
    let manager = try await TestManagers.walletAgnosticManager()
    let stub = StubWalletProvider()
    stub.id = .turnkey
    manager.register(stub)

    let resolved = try manager.provider(.turnkey)
    #expect(resolved.id == .turnkey)
  }

  @Test("provider(_:) throws for an unregistered id")
  func testProviderUnregisteredThrows() async throws {
    let manager = try await TestManagers.walletAgnosticManager()
    #expect(throws: RainSDKError.self) {
      _ = try manager.provider(.portal)
    }
  }

  @Test("setWalletProvider also registers for id resolution")
  func testSetWalletProviderRegisters() async throws {
    let manager = try await TestManagers.walletAgnosticManager()
    let stub = StubWalletProvider()
    stub.id = .portal
    manager.setWalletProvider(stub)

    let resolved = try manager.provider(.portal)
    #expect(resolved.id == .portal)
  }

  @Test("providers(matching:) returns only providers with the capability")
  func testProvidersMatchingCapability() async throws {
    let manager = try await TestManagers.walletAgnosticManager()
    let signer = StubWalletProvider()
    signer.id = .turnkey
    signer.capabilities = [.typedDataSigning, .feeEstimation]
    let plain = StubWalletProvider()
    plain.id = .portal
    plain.capabilities = []
    manager.register(signer)
    manager.register(plain)

    let signers = manager.providers(matching: .typedDataSigning)
    #expect(signers.count == 1)
    #expect(signers.first?.id == .turnkey)
  }

  @Test("multiple registered providers are each resolvable by id")
  func testMultipleProviders() async throws {
    let manager = try await TestManagers.walletAgnosticManager()
    let tk = StubWalletProvider(); tk.id = .turnkey
    let pt = StubWalletProvider(); pt.id = .portal
    manager.register(tk)
    manager.register(pt)

    #expect(try manager.provider(.turnkey).id == .turnkey)
    #expect(try manager.provider(.portal).id == .portal)
  }

  @Test("reset clears the registry")
  func testResetClearsRegistry() async throws {
    let manager = try await TestManagers.walletAgnosticManager()
    let stub = StubWalletProvider(); stub.id = .turnkey
    manager.register(stub)

    manager.reset()
    #expect(throws: RainSDKError.self) {
      _ = try manager.provider(.turnkey)
    }
  }
}
