import Foundation

public struct ServiceMetric: Sendable, Equatable {
  // MARK: - Properties

  public let service: String
  public let requestCount: Int
  public let averageDuration: TimeInterval?
}
