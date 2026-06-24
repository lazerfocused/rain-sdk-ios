import AuthenticationServices
import Foundation
import TurnkeyHttp
import TurnkeySwift

// MARK: - Map provider errors to RainSDKError

extension RainSDKError {
  /// Maps a thrown error to a `RainSDKError`. Handles already-`RainSDKError`, Turnkey (the
  /// in-core baseline provider), and the generic cases (network, user cancellation). Other
  /// providers map their own vendor errors at the adapter boundary (e.g. `RainSDKError.fromPortal`
  /// in `RainPortal`), so only `RainSDKError` reaches this point for them.
  ///
  /// SPI: out-of-package adapters call this as the generic fallback after handling their own
  /// vendor error types.
  @_spi(RainAdapters) public static func from(underlying error: Error) -> RainSDKError {
    if let rain = error as? RainSDKError { return rain }

    if let turnkeySwiftError = error as? TurnkeySwiftError {
      return mapTurnkeySwiftError(turnkeySwiftError)
    }

    if let turnkeyRequestError = error as? TurnkeyRequestError {
      return mapTurnkeyRequestError(turnkeyRequestError)
    }

    let nsError = error as NSError
    if nsError.domain == ASAuthorizationError.errorDomain,
       nsError.code == ASAuthorizationError.canceled.rawValue {
      return .userRejected
    }

    if nsError.domain == NSURLErrorDomain {
      return .networkError(underlying: error)
    }

    return .providerError(underlying: error)
  }

  private static func mapTurnkeySwiftError(_ error: TurnkeySwiftError) -> RainSDKError {
    switch error {
    case .invalidSession:
      return .tokenExpired

    case .failedToRetrieveOAuthCredential(_, let underlying):
      // May wrap ASAuthorizationError.canceled; recurse so user cancellation surfaces as .userRejected.
      return from(underlying: underlying)

    case .failedToSignPayload(let underlying),
         .failedToFetchWallets(let underlying),
         .failedToCreateWallet(let underlying),
         .failedToExportWallet(let underlying),
         .failedToImportWallet(let underlying),
         .failedToStoreSession(let underlying),
         .failedToRefreshSession(let underlying),
         .failedToLoginWithPasskey(let underlying),
         .failedToSignUpWithPasskey(let underlying),
         .failedToInitOtp(let underlying),
         .failedToVerifyOtp(let underlying),
         .failedToLoginWithOtp(let underlying),
         .failedToSignUpWithOtp(let underlying),
         .failedToCompleteOtp(let underlying),
         .failedToLoginWithOAuth(let underlying),
         .failedToSignUpWithOAuth(let underlying),
         .failedToCompleteOAuth(let underlying),
         .failedToUpdateUser(let underlying),
         .failedToUpdateUserEmail(let underlying),
         .failedToUpdateUserPhoneNumber(let underlying),
         .failedToFetchUser(let underlying),
         .failedToSetSelectedSession(let underlying),
         .keyGenerationFailed(let underlying),
         .failedToClearSession(let underlying):
      return from(underlying: underlying)

    case .invalidConfiguration,
         .missingAuthProxyConfiguration,
         .invalidRefreshTTL,
         .publicKeyMissing,
         .signingNotSupported,
         .invalidJWT,
         .invalidResponse,
         .keyAlreadyExists,
         .keyNotFound,
         .keyIndexFailed,
         .keychainAddFailed,
         .oauthInvalidURL,
         .oauthMissingIDToken:
      return .internalLogicError(details: "Turnkey: \(error.localizedDescription)")
    }
  }

  private static func mapTurnkeyRequestError(_ error: TurnkeyRequestError) -> RainSDKError {
    switch error {
    case .apiError(let statusCode, _):
      switch statusCode {
      case 401:
        return .tokenExpired
      case 403:
        return .unauthorized
      default:
        return .providerError(underlying: error)
      }
    case .network(let underlying):
      return .networkError(underlying: underlying)
    case .sdkError(let underlying), .unknown(let underlying):
      // Underlying may be a typed error (e.g. ASAuthorizationError.canceled, NSURLError); recurse to classify it.
      return from(underlying: underlying)
    case .invalidResponse:
      return .internalLogicError(details: "Turnkey invalid response")
    case .clientNotConfigured(let name):
      return .internalLogicError(details: "Turnkey client not configured: \(name)")
    }
  }
}
