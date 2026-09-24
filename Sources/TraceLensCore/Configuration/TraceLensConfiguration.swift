import Foundation

public struct TraceLensSettingsControls: Sendable {
  // MARK: - Properties

  public var defaultCapture: Bool
  public var networkCapture: Bool
  public var taskMetrics: Bool
  public var sensitiveDataPolicy: Bool
  public var maskTokens: Bool
  public var transactionLimit: Bool
  public var clearSession: Bool
  public var exportSession: Bool

  // MARK: - Initialization

  public init(
    defaultCapture: Bool = true,
    networkCapture: Bool = true,
    taskMetrics: Bool = true,
    sensitiveDataPolicy: Bool = true,
    maskTokens: Bool = true,
    transactionLimit: Bool = true,
    clearSession: Bool = true,
    exportSession: Bool = true
  ) {
    self.defaultCapture = defaultCapture
    self.networkCapture = networkCapture
    self.taskMetrics = taskMetrics
    self.sensitiveDataPolicy = sensitiveDataPolicy
    self.maskTokens = maskTokens
    self.transactionLimit = transactionLimit
    self.clearSession = clearSession
    self.exportSession = exportSession
  }

  public static let all = TraceLensSettingsControls()
}

public struct TraceLensConfiguration: Sendable {
  // MARK: - Capture

  public var defaultCapture: CaptureLevel
  public var configuredScopes: [ObservationRule]
  public var sensitiveDataPolicy: SensitiveDataPolicy
  public var endpointPresentation: EndpointPresentationStrategy
  public var serviceAliases: [String: String]
  public var captureNetworkTraffic: Bool
  public var captureTaskMetrics: Bool

  // MARK: - Session and UI

  public var sessionLimits: SessionLimits
  public var settingsControls: TraceLensSettingsControls

  // MARK: - Initialization

  public init(
    defaultCapture: CaptureLevel = .metadata,
    configuredScopes: [ObservationRule] = [],
    sensitiveDataPolicy: SensitiveDataPolicy = .redacted,
    endpointPresentation: EndpointPresentationStrategy = .automatic,
    serviceAliases: [String: String] = [:],
    captureNetworkTraffic: Bool = true,
    captureTaskMetrics: Bool = true,
    sessionLimits: SessionLimits = .default,
    settingsControls: TraceLensSettingsControls = .all
  ) {
    self.defaultCapture = defaultCapture
    self.configuredScopes = configuredScopes
    self.sensitiveDataPolicy = sensitiveDataPolicy
    self.endpointPresentation = endpointPresentation
    self.serviceAliases = serviceAliases
    self.captureNetworkTraffic = captureNetworkTraffic
    self.captureTaskMetrics = captureTaskMetrics
    self.sessionLimits = sessionLimits
    self.settingsControls = settingsControls
  }
}
