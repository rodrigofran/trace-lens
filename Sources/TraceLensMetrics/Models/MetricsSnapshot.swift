import Foundation

public struct MetricsSnapshot: Sendable, Equatable {
  // MARK: - Properties

  public let totalRequests: Int
  public let averageDuration: TimeInterval?
  public let errorRate: Double
  public let fullCaptureRatio: Double
  public let requestsOverTime: [TimeMetric]
  public let services: [ServiceMetric]
}
