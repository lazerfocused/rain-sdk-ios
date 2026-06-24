import Testing
import Foundation
import PortalSwift
@testable import RainPortal
@_spi(RainAdapters) @testable import RainSDK

@Suite("Portal Error Mapping Tests")
struct PortalErrorMappingTests {
  @Test("fromPortal maps PortalRequestsError.unauthorized to tokenExpired")
  func testPortalUnauthorizedMapsToTokenExpired() {
    #expect(RainSDKError.fromPortal(PortalRequestsError.unauthorized) == RainSDKError.tokenExpired)
  }

  @Test("fromPortal maps PortalRequestsError.clientError to providerError")
  func testPortalClientErrorMapsToProviderError() {
    let mapped = RainSDKError.fromPortal(PortalRequestsError.clientError("403 - Forbidden", url: "https://example.com"))
    if case .providerError = mapped {} else { Issue.record("Expected .providerError, got \(mapped)") }
  }
}
