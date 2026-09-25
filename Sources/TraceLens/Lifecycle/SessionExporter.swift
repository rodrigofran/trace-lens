import Foundation
import TraceLensCore
import TraceLensMetrics
import TraceLensStorage

enum SessionExporter {
  // MARK: - Export

  static func exportSession(
    snapshot: SessionSnapshot,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?,
    format: TraceLensExportFormat
  ) async throws -> URL {
    switch format {
    case .text:
      return try await exportSessionText(
        snapshot: snapshot,
        configuration: configuration,
        bodies: bodies
      )

    case .json:
      return try await exportSessionJSON(
        snapshot: snapshot,
        configuration: configuration,
        bodies: bodies
      )
    }
  }

  static func exportTransaction(
    _ transaction: NetworkTransaction,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?,
    format: TraceLensExportFormat
  ) async throws -> URL {
    switch format {
    case .text:
      return try await exportTransactionText(
        transaction,
        configuration: configuration,
        bodies: bodies
      )

    case .json:
      return try await exportTransactionJSON(
        transaction,
        configuration: configuration,
        bodies: bodies
      )
    }
  }

  // MARK: - JSON Export

  private static func exportSessionJSON(
    snapshot: SessionSnapshot,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?
  ) async throws -> URL {
    let transactions = try await snapshot.transactions.asyncMap {
      try await ExportedTransaction(
        transaction: $0,
        configuration: configuration,
        bodies: bodies
      )
    }
    let metrics = MetricsAggregator().aggregate(snapshot.transactions)
    let export = ExportedSession(
      session: snapshot.session,
      exportedAt: .now,
      transactions: transactions,
      metrics: .init(metrics)
    )

    return try write(
      export,
      named: "tracelens-session-\(snapshot.session.id.uuidString)-\(fileTimestamp()).json"
    )
  }

  private static func exportTransactionJSON(
    _ transaction: NetworkTransaction,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?
  ) async throws -> URL {
    let export = try await ExportedTransaction(
      transaction: transaction,
      configuration: configuration,
      bodies: bodies
    )

    return try write(
      export,
      named: "tracelens-request-\(transaction.id.uuidString)-\(fileTimestamp()).json"
    )
  }

  // MARK: - Text Export

  private static func exportSessionText(
    snapshot: SessionSnapshot,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?
  ) async throws -> URL {
    var sections = [
      "TraceLens — Sessão",
      "ID: \(snapshot.session.id.uuidString)",
      "Iniciada em: \(formatted(snapshot.session.startedAt))",
      "Exportada em: \(formatted(.now))",
      "Total de requests: \(snapshot.transactions.count)",
    ]

    for (index, transaction) in snapshot.transactions.enumerated() {
      sections.append(
        try await text(
          for: transaction,
          configuration: configuration,
          bodies: bodies,
          title: "Request \(index + 1)"
        )
      )
    }

    return try writeText(
      sections.joined(separator: "\n\n\(String(repeating: "=", count: 72))\n\n"),
      named: "tracelens-session-\(snapshot.session.id.uuidString)-\(fileTimestamp()).txt"
    )
  }

  private static func exportTransactionText(
    _ transaction: NetworkTransaction,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?
  ) async throws -> URL {
    let content = try await text(
      for: transaction,
      configuration: configuration,
      bodies: bodies,
      title: "TraceLens — Request"
    )

    return try writeText(
      content,
      named: "tracelens-request-\(transaction.id.uuidString)-\(fileTimestamp()).txt"
    )
  }

  // MARK: - Private Methods

  private static func write<T: Encodable>(_ value: T, named fileName: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    encoder.dateEncodingStrategy = .iso8601

    try encoder.encode(value).write(to: url, options: .atomic)

    return url
  }

  private static func writeText(_ value: String, named fileName: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

    try value.write(to: url, atomically: true, encoding: .utf8)

    return url
  }

  private static func text(
    for transaction: NetworkTransaction,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?,
    title: String
  ) async throws -> String {
    let requestHeaders = SensitiveData.headers(
      transaction.request.headers,
      policy: configuration.sensitiveDataPolicy
    )
    let requestBody = await text(
      for: transaction.request.body,
      contentType: contentType(in: transaction.request.headers),
      bodies: bodies
    )
    let responseHeaders = transaction.response.map {
      SensitiveData.headers($0.headers, policy: configuration.sensitiveDataPolicy)
    } ?? [:]
    let responseBody = await text(
      for: transaction.response?.body ?? .none,
      contentType: transaction.response?.mimeType
        ?? contentType(in: transaction.response?.headers ?? [:]),
      bodies: bodies
    )

    var lines = [
      title,
      "ID: \(transaction.id.uuidString)",
      "Estado: \(transaction.state.rawValue)",
      "Captura: \(transaction.captureLevel.rawValue)",
      "Iniciada em: \(formatted(transaction.startedAt))",
      "Finalizada em: \(transaction.finishedAt.map(formatted) ?? "—")",
      "",
      "REQUEST",
      "\(transaction.request.method.rawValue) \(transaction.request.parsed.fullURL)",
      "Serviço: \(transaction.request.parsed.displayService ?? "—")",
      "Serviço técnico: \(transaction.request.parsed.technicalService ?? "—")",
      "Headers:",
      headerText(requestHeaders),
      "Body:",
      requestBody,
      "",
      "RESPONSE",
      "Status: \(transaction.response.map { String($0.statusCode) } ?? "—")",
      "Headers:",
      headerText(responseHeaders),
      "Body:",
      responseBody,
    ]

    if let metrics = transaction.metrics {
      lines += [
        "",
        "MÉTRICAS",
        "Total: \(milliseconds(metrics.total))",
        "DNS: \(milliseconds(metrics.dns))",
        "TCP: \(milliseconds(metrics.tcp))",
        "TLS: \(milliseconds(metrics.tls))",
        "Primeiro byte: \(milliseconds(metrics.firstByte))",
        "Download: \(milliseconds(metrics.download))",
      ]
    }

    if let error = transaction.error {
      lines += [
        "",
        "ERRO",
        "\(error.domain) (\(error.code)): \(error.message)",
      ]
    }

    return lines.joined(separator: "\n")
  }

  private static func text(
    for reference: BodyReference,
    contentType: String?,
    bodies: TemporaryBodyStore?
  ) async -> String {
    let data: Data?

    switch reference.storage {
    case .inline:
      data = reference.data
    case .file:
      data = await bodies?.data(for: reference)
    case .none:
      return "Não capturado."
    case .truncated:
      return "Truncado. Tamanho original: \(reference.originalSize ?? 0) bytes."
    }

    guard let data else {
      return "Indisponível."
    }

    if let text = String(data: data, encoding: .utf8) {
      return prettyPrinted(text, contentType: contentType)
    }

    return "Conteúdo binário em Base64:\n\(data.base64EncodedString())"
  }

  private static func prettyPrinted(_ text: String, contentType: String?) -> String {
    let expectsJSON = contentType?.lowercased().contains("json") ?? true

    guard expectsJSON,
      let data = text.data(using: .utf8),
      let object = try? JSONSerialization.jsonObject(with: data),
      let formatted = try? JSONSerialization.data(
        withJSONObject: object,
        options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
      ),
      let result = String(data: formatted, encoding: .utf8)
    else {
      return text
    }

    return result
  }

  private static func headerText(_ headers: [String: String]) -> String {
    headers.isEmpty
      ? "—"
      : headers.sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
        .map { "\($0.key): \($0.value)" }
        .joined(separator: "\n")
  }

  private static func milliseconds(_ value: TimeInterval?) -> String {
    guard let value else {
      return "—"
    }

    return "\(Int((value * 1_000).rounded())) ms"
  }

  private static func formatted(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
  }

  private static func fileTimestamp() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd-HHmmss"

    return formatter.string(from: .now)
  }
}

// MARK: - Exported Session

private struct ExportedSession: Encodable {
  let format = "TraceLens Session"
  let version = 1
  let session: TraceLensSession
  let exportedAt: Date
  let transactions: [ExportedTransaction]
  let metrics: ExportedMetrics
}

// MARK: - Exported Transaction

private struct ExportedTransaction: Encodable {
  let format = "TraceLens Request"
  let version = 1
  let id: UUID
  let startedAt: Date
  let finishedAt: Date?
  let state: TransactionState
  let captureLevel: CaptureLevel
  let request: ExportedRequest
  let response: ExportedResponse?
  let metrics: NetworkMetrics?
  let error: NetworkError?

  init(
    transaction: NetworkTransaction,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?
  ) async throws {
    id = transaction.id
    startedAt = transaction.startedAt
    finishedAt = transaction.finishedAt
    state = transaction.state
    captureLevel = transaction.captureLevel
    metrics = transaction.metrics
    error = transaction.error

    request = try await .init(
      request: transaction.request,
      configuration: configuration,
      bodies: bodies
    )

    if let response = transaction.response {
      self.response = try await ExportedResponse(
        response: response,
        configuration: configuration,
        bodies: bodies
      )
    } else {
      response = nil
    }
  }
}

// MARK: - Exported Request

private struct ExportedRequest: Encodable {
  let url: String
  let method: String
  let service: String?
  let technicalService: String?
  let endpoint: String
  let host: String
  let headers: [String: String]
  let body: ExportedBody

  init(
    request: NetworkRequest,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?
  ) async throws {
    url = request.parsed.fullURL
    method = request.method.rawValue
    service = request.parsed.displayService
    technicalService = request.parsed.technicalService
    endpoint = request.parsed.endpoint
    host = request.parsed.host
    headers = SensitiveData.headers(request.headers, policy: configuration.sensitiveDataPolicy)
    body = await .init(
      reference: request.body,
      contentType: contentType(in: request.headers),
      bodies: bodies
    )
  }
}

// MARK: - Exported Response

private struct ExportedResponse: Encodable {
  let statusCode: Int
  let headers: [String: String]
  let mimeType: String?
  let expectedContentLength: Int64?
  let capturedSize: Int
  let receivedAt: Date
  let body: ExportedBody

  init(
    response: NetworkResponse,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?
  ) async throws {
    statusCode = response.statusCode
    headers = SensitiveData.headers(response.headers, policy: configuration.sensitiveDataPolicy)
    mimeType = response.mimeType
    expectedContentLength = response.expectedContentLength
    capturedSize = response.capturedSize
    receivedAt = response.receivedAt
    body = await .init(
      reference: response.body,
      contentType: response.mimeType ?? contentType(in: response.headers),
      bodies: bodies
    )
  }
}

// MARK: - Exported Body

private struct ExportedBody: Encodable {
  enum Encoding: String, Encodable {
    case utf8
    case base64
  }

  let storage: BodyReference.Storage
  let originalSize: Int?
  let contentType: String?
  let encoding: Encoding?
  let content: String?

  init(
    reference: BodyReference,
    contentType: String?,
    bodies: TemporaryBodyStore?
  ) async {
    storage = reference.storage
    originalSize = reference.originalSize
    self.contentType = contentType

    let data: Data?

    switch reference.storage {
    case .inline:
      data = reference.data
    case .file:
      data = await bodies?.data(for: reference)
    case .none, .truncated:
      data = nil
    }

    if let data, let text = String(data: data, encoding: .utf8) {
      encoding = .utf8
      content = text
    } else if let data {
      encoding = .base64
      content = data.base64EncodedString()
    } else {
      encoding = nil
      content = nil
    }
  }
}

// MARK: - Exported Metrics

private struct ExportedMetrics: Encodable {
  let totalRequests: Int
  let averageDuration: TimeInterval?
  let errorRate: Double
  let fullCaptureRatio: Double
  let services: [ExportedServiceMetric]

  init(_ metrics: MetricsSnapshot) {
    totalRequests = metrics.totalRequests
    averageDuration = metrics.averageDuration
    errorRate = metrics.errorRate
    fullCaptureRatio = metrics.fullCaptureRatio
    services = metrics.services.map(ExportedServiceMetric.init)
  }
}

private struct ExportedServiceMetric: Encodable {
  let service: String
  let requestCount: Int
  let averageDuration: TimeInterval?

  init(_ metric: ServiceMetric) {
    service = metric.service
    requestCount = metric.requestCount
    averageDuration = metric.averageDuration
  }
}

// MARK: - Helpers

private func contentType(in headers: [String: String]) -> String? {
  headers.first { key, _ in
    key.caseInsensitiveCompare("Content-Type") == .orderedSame
  }?.value
}

private extension Collection {
  func asyncMap<T>(
    _ transform: (Element) async throws -> T
  ) async rethrows -> [T] {
    var result: [T] = []
    result.reserveCapacity(count)

    for element in self {
      result.append(try await transform(element))
    }

    return result
  }
}
