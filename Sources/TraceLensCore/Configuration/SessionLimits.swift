import Foundation

public struct SessionLimits: Sendable, Codable, Equatable {
  // MARK: - Properties

  public var maxTransactions: Int
  public var maxBodyBytes: Int
  public var maxTemporaryStorageBytes: Int64

  // MARK: - Initialization

  public init(
    maxTransactions: Int = 1_000,
    maxBodyBytes: Int = 5 * 1_024 * 1_024,
    maxTemporaryStorageBytes: Int64 = 100 * 1_024 * 1_024
  ) {
    self.maxTransactions = maxTransactions
    self.maxBodyBytes = maxBodyBytes
    self.maxTemporaryStorageBytes = maxTemporaryStorageBytes
  }

  public static let `default` = SessionLimits()
}
