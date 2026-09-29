import Foundation
import TraceLensCore
import TraceLensMetrics
import TraceLensStorage

enum SessionJSONExporter {
  static func export(snapshot: SessionSnapshot, configuration: TraceLensConfiguration, bodies: TemporaryBodyStore?) async throws -> URL {
    let transactions = try await snapshot.transactions.asyncMap {
      try await ExportedTransaction(transaction: $0, configuration: configuration, bodies: bodies)
    }
    let export = ExportedSession(
      session: snapshot.session,
      exportedAt: .now,
      transactions: transactions,
      metrics: .init(MetricsAggregator().aggregate(snapshot.transactions))
    )
    return try ExportFileWriter.write(export, named: "tracelens-session-\(snapshot.session.id.uuidString)-\(ExportFileWriter.timestamp()).json")
  }

  static func export(_ transaction: NetworkTransaction, configuration: TraceLensConfiguration, bodies: TemporaryBodyStore?) async throws -> URL {
    let export = try await ExportedTransaction(transaction: transaction, configuration: configuration, bodies: bodies)
    return try ExportFileWriter.write(export, named: "tracelens-request-\(transaction.id.uuidString)-\(ExportFileWriter.timestamp()).json")
  }
}

private struct ExportedSession: Encodable {
  let format = "TraceLens Session"
  let version = 1
  let session: TraceLensSession
  let exportedAt: Date
  let transactions: [ExportedTransaction]
  let metrics: ExportedMetrics
}

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

  init(transaction: NetworkTransaction, configuration: TraceLensConfiguration, bodies: TemporaryBodyStore?) async throws {
    id = transaction.id
    startedAt = transaction.startedAt
    finishedAt = transaction.finishedAt
    state = transaction.state
    captureLevel = transaction.captureLevel
    metrics = transaction.metrics
    error = transaction.error
    request = try await .init(request: transaction.request, configuration: configuration, bodies: bodies)
    response = try await transaction.response.asyncMap { try await ExportedResponse(response: $0, configuration: configuration, bodies: bodies) }
  }
}

private struct ExportedRequest: Encodable {
  let url: String
  let method: String
  let service: String?
  let technicalService: String?
  let endpoint: String
  let host: String
  let headers: [String: String]
  let body: ExportedBody

  init(request: NetworkRequest, configuration: TraceLensConfiguration, bodies: TemporaryBodyStore?) async throws {
    url = request.parsed.fullURL
    method = request.method.rawValue
    service = request.parsed.displayService
    technicalService = request.parsed.technicalService
    endpoint = request.parsed.endpoint
    host = request.parsed.host
    headers = SensitiveData.headers(request.headers, policy: configuration.sensitiveDataPolicy)
    body = await .init(reference: request.body, contentType: contentType(in: request.headers), bodies: bodies)
  }
}

private struct ExportedResponse: Encodable {
  let statusCode: Int
  let headers: [String: String]
  let mimeType: String?
  let expectedContentLength: Int64?
  let capturedSize: Int
  let receivedAt: Date
  let body: ExportedBody

  init(response: NetworkResponse, configuration: TraceLensConfiguration, bodies: TemporaryBodyStore?) async throws {
    statusCode = response.statusCode
    headers = SensitiveData.headers(response.headers, policy: configuration.sensitiveDataPolicy)
    mimeType = response.mimeType
    expectedContentLength = response.expectedContentLength
    capturedSize = response.capturedSize
    receivedAt = response.receivedAt
    body = await .init(reference: response.body, contentType: response.mimeType ?? contentType(in: response.headers), bodies: bodies)
  }
}

private struct ExportedBody: Encodable {
  enum Encoding: String, Encodable { case utf8, base64 }
  let storage: BodyReference.Storage
  let originalSize: Int?
  let contentType: String?
  let encoding: Encoding?
  let content: String?

  init(reference: BodyReference, contentType: String?, bodies: TemporaryBodyStore?) async {
    storage = reference.storage
    originalSize = reference.originalSize
    self.contentType = contentType
    let data: Data?
    switch reference.storage {
    case .inline: data = reference.data
    case .file: data = await bodies?.data(for: reference)
    case .none, .truncated: data = nil
    }
    if let data, let text = String(data: data, encoding: .utf8) {
      encoding = .utf8; content = text
    } else if let data {
      encoding = .base64; content = data.base64EncodedString()
    } else { encoding = nil; content = nil }
  }
}

private struct ExportedMetrics: Encodable {
  let totalRequests: Int
  let averageDuration: TimeInterval?
  let errorRate: Double
  let fullCaptureRatio: Double
  let services: [ExportedServiceMetric]
  init(_ metrics: MetricsSnapshot) {
    totalRequests = metrics.totalRequests; averageDuration = metrics.averageDuration
    errorRate = metrics.errorRate; fullCaptureRatio = metrics.fullCaptureRatio
    services = metrics.services.map(ExportedServiceMetric.init)
  }
}

private struct ExportedServiceMetric: Encodable {
  let service: String
  let requestCount: Int
  let averageDuration: TimeInterval?
  init(_ metric: ServiceMetric) { service = metric.service; requestCount = metric.requestCount; averageDuration = metric.averageDuration }
}

func contentType(in headers: [String: String]) -> String? {
  headers.first { $0.key.caseInsensitiveCompare("Content-Type") == .orderedSame }?.value
}

private extension Collection {
  func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
    var result: [T] = []; result.reserveCapacity(count)
    for element in self { result.append(try await transform(element)) }
    return result
  }
}

private extension Optional {
  func asyncMap<T>(_ transform: (Wrapped) async throws -> T) async rethrows -> T? {
    guard let self else { return nil }
    return try await transform(self)
  }
}
