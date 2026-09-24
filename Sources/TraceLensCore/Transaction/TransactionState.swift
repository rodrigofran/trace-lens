import Foundation

public enum TransactionState: String, Codable, Sendable {
  case pending
  case running
  case completed
  case failed
  case cancelled
}
