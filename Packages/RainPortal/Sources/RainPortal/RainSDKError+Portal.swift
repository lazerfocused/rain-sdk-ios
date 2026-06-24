import Foundation
import PortalSwift
@_spi(RainAdapters) import RainSDK

// Portal vendor-error mapping. Lives with the Portal adapter so core's central mapper
// (`RainSDKError.from(underlying:)`) stays vendor-free. The adapter maps Portal errors to
// `RainSDKError` at its boundary, so only domain errors ever leave the provider.

extension RainSDKError {
  /// Maps a Portal vendor error to `RainSDKError`, delegating anything non-Portal to the
  /// generic `from(underlying:)` (which also handles already-`RainSDKError`, NSURL, etc.).
  static func fromPortal(_ error: Error) -> RainSDKError {
    if let rain = error as? RainSDKError { return rain }

    if let requestError = error as? PortalRequestsError {
      return mapPortalRequestsError(requestError)
    }

    if let mpcError = error as? PortalMpcError {
      return mapPortalMpcError(mpcError)
    }

    if let rpcError = error as? PortalRpcError {
      return mapPortalRpcError(rpcError)
    }

    return .from(underlying: error)
  }

  private static func mapPortalRequestsError(_ error: PortalRequestsError) -> RainSDKError {
    switch error {
    case .unauthorized:
      // Portal routes HTTP 401 to .unauthorized upstream (see PortalRequests.buildError),
      // so this is the only path token-expired errors reach the SDK through.
      return .tokenExpired
    case .clientError, .internalServerError, .redirectError:
      return .providerError(underlying: error)
    default:
      return .providerError(underlying: error)
    }
  }

  private static func mapPortalMpcError(_ error: PortalMpcError) -> RainSDKError {
    let code = error.id.flatMap { Int($0) }
    if code == 320 || code == PortalErrorCodes.INVALID_API_KEY.rawValue {
      return .tokenExpired
    }
    return .providerError(underlying: error)
  }

  private static func mapPortalRpcError(_ error: PortalRpcError) -> RainSDKError {
    // Code `3` is returned for "execution reverted" — not declared by PortalSwift.
    if error.code == 3 {
      return .withdrawalRevertedByNetwork
    }
    return .providerError(underlying: error)
  }
}
