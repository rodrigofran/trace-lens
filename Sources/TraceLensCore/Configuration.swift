import Foundation

public struct RequestMatcher: Sendable, Codable, Equatable {
    public var scheme: String?; public var host: String?; public var pathPrefix: String?; public var methods: Set<HTTPMethod>?
    public init(scheme: String? = nil, host: String? = nil, pathPrefix: String? = nil, methods: Set<HTTPMethod>? = nil) { self.scheme = scheme?.lowercased(); self.host = host?.lowercased(); self.pathPrefix = pathPrefix; self.methods = methods }
    public func matches(_ url: URL, method: HTTPMethod) -> Bool { (scheme == nil || url.scheme?.lowercased() == scheme) && (host == nil || url.host?.lowercased() == host) && (pathPrefix == nil || url.path.hasPrefix(pathPrefix!)) && (methods == nil || methods!.contains(method)) }
    public var specificity: Int { (scheme == nil ? 0 : 1) + (host == nil ? 0 : 4) + (pathPrefix?.count ?? 0) + (methods == nil ? 0 : 2) }
}
public struct ObservationRule: Sendable, Codable, Equatable, Identifiable {
    public let id: UUID; public let matcher: RequestMatcher; public let captureLevel: CaptureLevel; public let origin: ObservationRuleOrigin
    public init(id: UUID = UUID(), matcher: RequestMatcher, captureLevel: CaptureLevel, origin: ObservationRuleOrigin = .configured) { self.id = id; self.matcher = matcher; self.captureLevel = captureLevel; self.origin = origin }
    public static func host(_ host: String, capture: CaptureLevel, origin: ObservationRuleOrigin = .configured) -> Self { .init(matcher: .init(host: host), captureLevel: capture, origin: origin) }
}
public struct TraceLensSettingsControls: Sendable {
    public var defaultCapture: Bool; public var networkCapture: Bool; public var taskMetrics: Bool; public var sensitiveDataPolicy: Bool; public var maskTokens: Bool; public var transactionLimit: Bool; public var clearSession: Bool; public var exportSession: Bool
    public init(defaultCapture: Bool = true, networkCapture: Bool = true, taskMetrics: Bool = true, sensitiveDataPolicy: Bool = true, maskTokens: Bool = true, transactionLimit: Bool = true, clearSession: Bool = true, exportSession: Bool = true) { self.defaultCapture = defaultCapture; self.networkCapture = networkCapture; self.taskMetrics = taskMetrics; self.sensitiveDataPolicy = sensitiveDataPolicy; self.maskTokens = maskTokens; self.transactionLimit = transactionLimit; self.clearSession = clearSession; self.exportSession = exportSession }
    public static let all = TraceLensSettingsControls()
}

public struct TraceLensConfiguration: Sendable {
    public var defaultCapture: CaptureLevel; public var configuredScopes: [ObservationRule]; public var sensitiveDataPolicy: SensitiveDataPolicy; public var endpointPresentation: EndpointPresentationStrategy; public var serviceAliases: [String: String]; public var captureNetworkTraffic: Bool; public var captureTaskMetrics: Bool; public var sessionLimits: SessionLimits; public var settingsControls: TraceLensSettingsControls
    public init(defaultCapture: CaptureLevel = .metadata, configuredScopes: [ObservationRule] = [], sensitiveDataPolicy: SensitiveDataPolicy = .redacted, endpointPresentation: EndpointPresentationStrategy = .automatic, serviceAliases: [String: String] = [:], captureNetworkTraffic: Bool = true, captureTaskMetrics: Bool = true, sessionLimits: SessionLimits = .default, settingsControls: TraceLensSettingsControls = .all) { self.defaultCapture = defaultCapture; self.configuredScopes = configuredScopes; self.sensitiveDataPolicy = sensitiveDataPolicy; self.endpointPresentation = endpointPresentation; self.serviceAliases = serviceAliases; self.captureNetworkTraffic = captureNetworkTraffic; self.captureTaskMetrics = captureTaskMetrics; self.sessionLimits = sessionLimits; self.settingsControls = settingsControls }
}
public struct ObservationRuleEngine: Sendable {
    public init() {}
    public func resolve(url: URL, method: HTTPMethod, configured: [ObservationRule], session: [ObservationRule], next: [ObservationRule], defaultCapture: CaptureLevel) -> ObservationRule? { for rules in [next, session, configured] { if let match = rules.filter({ $0.matcher.matches(url, method: method) }).max(by: { $0.matcher.specificity < $1.matcher.specificity }) { return match } }; return nil }
    public func captureLevel(url: URL, method: HTTPMethod, configured: [ObservationRule], session: [ObservationRule], next: [ObservationRule], defaultCapture: CaptureLevel) -> CaptureLevel { resolve(url: url, method: method, configured: configured, session: session, next: next, defaultCapture: defaultCapture)?.captureLevel ?? defaultCapture }
}
public struct EndpointParser: Sendable {
    public let strategy: EndpointPresentationStrategy; public let aliases: [String: String]
    public init(strategy: EndpointPresentationStrategy = .automatic, aliases: [String: String] = [:]) { self.strategy = strategy; self.aliases = aliases }
    public func parse(_ url: URL) -> ParsedEndpoint { let host = url.host ?? ""; let parts = url.path.split(separator: "/").map(String.init); var service: String?; var endpoint = url.path.isEmpty ? "/" : url.path
        switch strategy { case .raw: break; case .serviceAfterPathPrefix(let prefix): let prefixParts = prefix.split(separator: "/").map(String.init); if parts.starts(with: prefixParts), parts.count > prefixParts.count { service = parts[prefixParts.count]; let remaining = parts.dropFirst(prefixParts.count + 1); endpoint = remaining.isEmpty ? "/" : "/" + remaining.joined(separator: "/") }
        case .serviceAtPathIndex(let index): if parts.indices.contains(index) { service = parts[index]; let remaining = parts.dropFirst(index + 1); endpoint = remaining.isEmpty ? "/" : "/" + remaining.joined(separator: "/") }
        case .automatic: if parts.count >= 2 { service = parts.first; endpoint = "/" + parts.dropFirst().joined(separator: "/") } }
        return .init(host: host, technicalService: service, displayService: service.flatMap { aliases[$0] } ?? service, endpoint: endpoint, fullURL: url.absoluteString) }
}
public enum SensitiveData {
    public static func value(_ value: String, key: String, policy: SensitiveDataPolicy) -> String { guard policy == .redacted else { return value }; let lower = key.lowercased(); return ["authorization", "cookie", "set-cookie", "token", "password", "secret", "api-key", "x-api-key"].contains(where: lower.contains) ? "••••••••" : value }
    public static func headers(_ headers: [String: String], policy: SensitiveDataPolicy) -> [String: String] { Dictionary(uniqueKeysWithValues: headers.map { ($0.key, value($0.value, key: $0.key, policy: policy)) }) }
}
