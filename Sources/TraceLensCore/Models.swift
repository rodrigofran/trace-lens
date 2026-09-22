import Foundation

public enum CaptureLevel: String, Codable, Sendable, CaseIterable { case none, metadata, full }
public enum SensitiveDataPolicy: String, Codable, Sendable { case visible, redacted }
public enum TransactionState: String, Codable, Sendable { case pending, running, completed, failed, cancelled }
public enum HTTPMethod: String, Codable, Sendable, CaseIterable, Hashable {
    case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE", head = "HEAD", options = "OPTIONS", other = "OTHER"
    public init(_ value: String?) { self = HTTPMethod(rawValue: (value ?? "GET").uppercased()) ?? .other }
}
public enum ObservationRuleOrigin: String, Codable, Sendable { case configured, session, nextRequest }
public enum EndpointPresentationStrategy: Sendable, Equatable {
    case automatic
    case raw
    case serviceAfterPathPrefix(String)
    /// Uses a zero-based path component as the service title. For example,
    /// `/v2/sicredi/payments/orders` with index `2` presents `payments`.
    case serviceAtPathIndex(Int)
}
public struct SessionLimits: Sendable, Codable, Equatable {
    public var maxTransactions: Int; public var maxBodyBytes: Int; public var maxTemporaryStorageBytes: Int64
    public init(maxTransactions: Int = 1_000, maxBodyBytes: Int = 5 * 1_024 * 1_024, maxTemporaryStorageBytes: Int64 = 100 * 1_024 * 1_024) { self.maxTransactions = maxTransactions; self.maxBodyBytes = maxBodyBytes; self.maxTemporaryStorageBytes = maxTemporaryStorageBytes }
    public static let `default` = SessionLimits()
}
public struct BodyReference: Sendable, Codable, Equatable {
    public enum Storage: String, Codable, Sendable { case none, inline, file, truncated }
    public let storage: Storage; public let data: Data?; public let fileName: String?; public let originalSize: Int?
    public init(storage: Storage = .none, data: Data? = nil, fileName: String? = nil, originalSize: Int? = nil) { self.storage = storage; self.data = data; self.fileName = fileName; self.originalSize = originalSize }
    public static let none = BodyReference()
}
public struct ParsedEndpoint: Sendable, Codable, Equatable {
    public let host: String; public let technicalService: String?; public let displayService: String?; public let endpoint: String; public let fullURL: String
    public init(host: String, technicalService: String?, displayService: String?, endpoint: String, fullURL: String) { self.host = host; self.technicalService = technicalService; self.displayService = displayService; self.endpoint = endpoint; self.fullURL = fullURL }
}
public struct NetworkRequest: Sendable, Codable, Equatable {
    public let url: URL; public let method: HTTPMethod; public let parsed: ParsedEndpoint; public let startedAt: Date; public var headers: [String: String]; public var body: BodyReference; public var estimatedSize: Int?
    public init(url: URL, method: HTTPMethod, parsed: ParsedEndpoint, startedAt: Date = .now, headers: [String: String] = [:], body: BodyReference = .none, estimatedSize: Int? = nil) { self.url = url; self.method = method; self.parsed = parsed; self.startedAt = startedAt; self.headers = headers; self.body = body; self.estimatedSize = estimatedSize }
}
public struct NetworkResponse: Sendable, Codable, Equatable {
    public var statusCode: Int; public var headers: [String: String]; public var body: BodyReference; public var mimeType: String?; public var expectedContentLength: Int64?; public var capturedSize: Int; public var receivedAt: Date
    public init(statusCode: Int, headers: [String: String] = [:], body: BodyReference = .none, mimeType: String? = nil, expectedContentLength: Int64? = nil, capturedSize: Int = 0, receivedAt: Date = .now) { self.statusCode = statusCode; self.headers = headers; self.body = body; self.mimeType = mimeType; self.expectedContentLength = expectedContentLength; self.capturedSize = capturedSize; self.receivedAt = receivedAt }
}
public struct NetworkError: Sendable, Codable, Equatable { public let domain: String; public let code: Int; public let message: String; public init(_ error: Error) { let e = error as NSError; domain = e.domain; code = e.code; message = e.localizedDescription }; public init(domain: String, code: Int, message: String) { self.domain = domain; self.code = code; self.message = message } }
public struct NetworkMetrics: Sendable, Codable, Equatable { public var total: TimeInterval?; public var dns: TimeInterval?; public var tcp: TimeInterval?; public var tls: TimeInterval?; public var upload: TimeInterval?; public var firstByte: TimeInterval?; public var download: TimeInterval?; public var protocolName: String?; public var reusedConnection: Bool?; public var redirectCount: Int; public init(total: TimeInterval? = nil, dns: TimeInterval? = nil, tcp: TimeInterval? = nil, tls: TimeInterval? = nil, upload: TimeInterval? = nil, firstByte: TimeInterval? = nil, download: TimeInterval? = nil, protocolName: String? = nil, reusedConnection: Bool? = nil, redirectCount: Int = 0) { self.total = total; self.dns = dns; self.tcp = tcp; self.tls = tls; self.upload = upload; self.firstByte = firstByte; self.download = download; self.protocolName = protocolName; self.reusedConnection = reusedConnection; self.redirectCount = redirectCount } }
public struct NetworkTransaction: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID; public let startedAt: Date; public var finishedAt: Date?; public var request: NetworkRequest; public var response: NetworkResponse?; public var metrics: NetworkMetrics?; public var error: NetworkError?; public var state: TransactionState; public let captureLevel: CaptureLevel
    public init(id: UUID = UUID(), startedAt: Date = .now, request: NetworkRequest, response: NetworkResponse? = nil, metrics: NetworkMetrics? = nil, error: NetworkError? = nil, state: TransactionState = .running, captureLevel: CaptureLevel) { self.id = id; self.startedAt = startedAt; self.finishedAt = nil; self.request = request; self.response = response; self.metrics = metrics; self.error = error; self.state = state; self.captureLevel = captureLevel }
    public var duration: TimeInterval? { metrics?.total ?? finishedAt.map { $0.timeIntervalSince(startedAt) } }
}
public struct TraceLensSession: Sendable, Codable { public let id: UUID; public let startedAt: Date; public init(id: UUID = UUID(), startedAt: Date = .now) { self.id = id; self.startedAt = startedAt } }
