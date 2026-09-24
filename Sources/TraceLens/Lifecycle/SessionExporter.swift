import Foundation
import TraceLensCore
import TraceLensMetrics
import TraceLensStorage

enum SessionExporter {
  // MARK: - Export

  static func export(
    snapshot: SessionSnapshot,
    configuration: TraceLensConfiguration
  ) throws -> URL {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(
      "TraceLensSession-\(snapshot.session.id.uuidString).tracelens",
      isDirectory: true
    )

    try? FileManager.default.removeItem(at: root)

    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("requests", isDirectory: true),
      withIntermediateDirectories: true
    )

    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("responses", isDirectory: true),
      withIntermediateDirectories: true
    )

    var exported = snapshot.transactions

    if configuration.sensitiveDataPolicy == .redacted {
      redactHeaders(in: &exported)
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601

    try encoder.encode(exported).write(to: root.appendingPathComponent("transactions.json"))
    try exportMetrics(for: snapshot.transactions, to: root)
    try exportManifest(for: snapshot, to: root)

    return root
  }

  // MARK: - Private Methods

  private static func redactHeaders(in transactions: inout [NetworkTransaction]) {
    for index in transactions.indices {
      transactions[index].request.headers = SensitiveData.headers(
        transactions[index].request.headers,
        policy: .redacted
      )

      if var response = transactions[index].response {
        response.headers = SensitiveData.headers(response.headers, policy: .redacted)
        transactions[index].response = response
      }
    }
  }

  private static func exportMetrics(
    for transactions: [NetworkTransaction],
    to root: URL
  ) throws {
    let metrics = MetricsAggregator().aggregate(transactions)
    let data = try JSONSerialization.data(
      withJSONObject: [
        "totalRequests": metrics.totalRequests,
        "errorRate": metrics.errorRate,
        "fullCaptureRatio": metrics.fullCaptureRatio,
      ],
      options: [.prettyPrinted, .sortedKeys]
    )

    try data.write(to: root.appendingPathComponent("metrics.json"))
  }

  private static func exportManifest(
    for snapshot: SessionSnapshot,
    to root: URL
  ) throws {
    let data = try JSONSerialization.data(
      withJSONObject: [
        "sessionID": snapshot.session.id.uuidString,
        "startedAt": ISO8601DateFormatter().string(from: snapshot.session.startedAt),
        "format": "TraceLens Session",
      ],
      options: [.prettyPrinted, .sortedKeys]
    )

    try data.write(to: root.appendingPathComponent("manifest.json"))
  }
}
