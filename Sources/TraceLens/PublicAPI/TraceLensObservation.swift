import Foundation

/// Identifies a request being observed by TraceLens without altering the request lifecycle.
public struct TraceLensObservation: Sendable, Hashable {
  let transactionID: UUID
}
