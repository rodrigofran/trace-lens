import Foundation
import TraceLensCore

public struct SessionSnapshot: Sendable {
  public let session: TraceLensSession
  public let transactions: [NetworkTransaction]
  public let configuredRules: [ObservationRule]
  public let sessionRules: [ObservationRule]
  public let nextRules: [ObservationRule]
  public let discoveredHosts: [String]
}

public actor SessionStore {
  // MARK: - Session state

  private var session: TraceLensSession
  private var transactions: [UUID: NetworkTransaction] = [:]
  private var order: [UUID] = []

  // MARK: - Observation rules

  private var configuredRules: [ObservationRule]
  private var sessionRules: [ObservationRule] = []
  private var nextRules: [ObservationRule] = []

  // MARK: - Storage state

  private var hosts: Set<String> = []
  private var limits: SessionLimits
  private var continuations: [UUID: AsyncStream<SessionSnapshot>.Continuation] = [:]

  // MARK: - Initialization

  public init(configuration: TraceLensConfiguration) {
    session = TraceLensSession()
    configuredRules = configuration.configuredScopes
    limits = configuration.sessionLimits
  }

  // MARK: - Snapshots

  public func snapshot() -> SessionSnapshot {
    .init(
      session: session,
      transactions: order.reversed().compactMap { transactions[$0] },
      configuredRules: configuredRules,
      sessionRules: sessionRules,
      nextRules: nextRules,
      discoveredHosts: hosts.sorted()
    )
  }

  public func updates() -> AsyncStream<SessionSnapshot> {
    let token = UUID()
    return AsyncStream { continuation in
      continuations[token] = continuation
      continuation.yield(snapshot())
      continuation.onTermination = { @Sendable _ in
        Task {
          await self.removeContinuation(token)
        }
      }
    }
  }

  // MARK: - Transactions

  private func removeContinuation(_ token: UUID) {
    continuations[token] = nil
  }

  private func publish() {
    let value = snapshot()

    for continuation in continuations.values {
      continuation.yield(value)
    }
  }

  public func resolve(url: URL, method: HTTPMethod, defaultCapture: CaptureLevel) -> (
    CaptureLevel, UUID?
  ) {
    let engine = ObservationRuleEngine()

    let matching = engine.resolve(
      url: url,
      method: method,
      configured: configuredRules,
      session: sessionRules,
      next: nextRules,
      defaultCapture: defaultCapture
    )

    if let matching, matching.origin == .nextRequest {
      nextRules.removeAll { $0.id == matching.id }
      publish()
    }
    return (matching?.captureLevel ?? defaultCapture, matching?.id)
  }
  @discardableResult
  public func begin(_ transaction: NetworkTransaction) -> Bool {
    guard transactions.count < limits.maxTransactions else {
      return false
    }

    transactions[transaction.id] = transaction
    order.append(transaction.id)

    if !transaction.request.parsed.host.isEmpty {
      hosts.insert(transaction.request.parsed.host)
    }

    publish()

    return true
  }

  public func transaction(_ id: UUID) -> NetworkTransaction? {
    transactions[id]
  }

  public func update(_ id: UUID, _ change: @Sendable (inout NetworkTransaction) -> Void) {
    guard var value = transactions[id] else {
      return
    }

    change(&value)
    transactions[id] = value

    publish()
  }

  // MARK: - Rules

  public func addSessionRule(_ rule: ObservationRule) {
    sessionRules.append(rule)
    publish()
  }

  public func addNextRule(_ rule: ObservationRule) {
    nextRules.append(rule)
    publish()
  }

  public func removeSessionRule(_ id: UUID) {
    sessionRules.removeAll { $0.id == id }
    publish()
  }

  // MARK: - Limits and cleanup

  public func updateLimits(_ limits: SessionLimits) {
    self.limits = limits
    publish()
  }

  public func clear() {
    transactions.removeAll()
    order.removeAll()
    sessionRules.removeAll()
    nextRules.removeAll()
    hosts.removeAll()
    session = TraceLensSession()
    publish()
  }
}
