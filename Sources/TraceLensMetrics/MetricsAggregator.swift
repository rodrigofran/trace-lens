import Foundation
import TraceLensCore

public struct ServiceMetric: Sendable, Equatable {
  public let service: String
  public let requestCount: Int
  public let averageDuration: TimeInterval?
}

public struct TimeMetric: Sendable, Equatable {
  public let date: Date
  public let count: Int
}

public struct MetricsSnapshot: Sendable, Equatable {
  public let totalRequests: Int
  public let averageDuration: TimeInterval?
  public let errorRate: Double
  public let fullCaptureRatio: Double
  public let requestsOverTime: [TimeMetric]
  public let services: [ServiceMetric]
}

public struct MetricsAggregator: Sendable {
  // MARK: - Initialization

  public init() {}

  // MARK: - Aggregation

  public func aggregate(_ transactions: [NetworkTransaction]) -> MetricsSnapshot {
    let total = transactions.count
    let complete = transactions.compactMap(\.duration)

    let errors = transactions.filter {
      $0.error != nil || ($0.response?.statusCode ?? 0) >= 400
    }
    .count

    let full = transactions.filter { $0.captureLevel == .full }.count

    let grouped = Dictionary(
      grouping: transactions,
      by: {
        $0.request.parsed.displayService ?? $0.request.parsed.technicalService
          ?? $0.request.parsed.host
      })

    let services = grouped.map { key, values in
      let durations = values.compactMap(\.duration)

      return ServiceMetric(
        service: key,
        requestCount: values.count,
        averageDuration: durations.isEmpty
          ? nil
          : durations.reduce(0, +) / Double(durations.count)
      )
    }.sorted(by: { $0.requestCount > $1.requestCount })

    let calendar = Calendar.current

    let time = Dictionary(
      grouping: transactions,
      by: { calendar.date(bySetting: .second, value: 0, of: $0.startedAt) ?? $0.startedAt }
    ).map { TimeMetric(date: $0.key, count: $0.value.count) }
      .sorted(by: { $0.date < $1.date })

    return .init(
      totalRequests: total,
      averageDuration: complete.isEmpty ? nil : complete.reduce(0, +) / Double(complete.count),
      errorRate: total == 0 ? 0 : Double(errors) / Double(total),
      fullCaptureRatio: total == 0 ? 0 : Double(full) / Double(total),
      requestsOverTime: time,
      services: services
    )
  }
}
