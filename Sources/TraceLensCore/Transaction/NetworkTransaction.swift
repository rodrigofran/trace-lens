import Foundation

public struct NetworkTransaction: Identifiable, Sendable, Codable, Equatable {
  // MARK: - Properties

  public let id: UUID
  public let startedAt: Date
  public var finishedAt: Date?
  public var request: NetworkRequest
  public var response: NetworkResponse?
  public var metrics: NetworkMetrics?
  public var error: NetworkError?
  public var state: TransactionState
  public let captureLevel: CaptureLevel

  // MARK: - Initialization

  public init(
    id: UUID = UUID(),
    startedAt: Date = .now,
    request: NetworkRequest,
    response: NetworkResponse? = nil,
    metrics: NetworkMetrics? = nil,
    error: NetworkError? = nil,
    state: TransactionState = .running,
    captureLevel: CaptureLevel
  ) {
    self.id = id
    self.startedAt = startedAt
    self.finishedAt = nil
    self.request = request
    self.response = response
    self.metrics = metrics
    self.error = error
    self.state = state
    self.captureLevel = captureLevel
  }

  public var duration: TimeInterval? {
    metrics?.total ?? finishedAt.map { $0.timeIntervalSince(startedAt) }
  }
}
