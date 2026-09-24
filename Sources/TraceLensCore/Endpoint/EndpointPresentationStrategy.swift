import Foundation

public enum EndpointPresentationStrategy: Sendable, Equatable {
  case automatic
  case raw
  case serviceAfterPathPrefix(String)

  /// Uses a zero-based path component as the service title. For example,
  /// `/v2/sicredi/payments/orders` with index `2` presents `payments`.
  case serviceAtPathIndex(Int)
}
