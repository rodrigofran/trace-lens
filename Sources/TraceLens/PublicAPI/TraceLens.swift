@preconcurrency import Foundation
import TraceLensCapture
@_exported import TraceLensCore
import TraceLensCore

public enum TraceLens {
  // MARK: - Dependencies

  private static let coordinator = TraceLensCoordinator()

  /// Shared UIKit-friendly presenter. Call `TraceLens.shared.show()`.
  public static let shared = TraceLensPresenter()

  @MainActor
  static var presentation = TraceLensPresentation()

  // MARK: - Lifecycle

  public static func start(configuration: TraceLensConfiguration = .init()) {
    Task {
      await coordinator.start(configuration)
    }
  }

  public static func stop() {
    Task {
      await coordinator.stop()
    }
  }

  public static func updateConfiguration(_ configuration: TraceLensConfiguration) {
    Task {
      await coordinator.update(configuration)
    }
  }

  // MARK: - Presentation

  public static func show() {
    shared.show()
  }

  public static func hide() {
    shared.hide()
  }

  // MARK: - Session

  public static func clearSession() async {
    await coordinator.clear()
  }

  public static func exportSession() async throws -> URL {
    try await coordinator.export()
  }

  // MARK: - Passive Observation

  /// Begins passive observation of a request already owned by the host networking stack.
  ///
  /// Call this immediately before the host starts its real request. Unlike URLProtocol
  /// instrumentation, this API does not create a URLSession, forward traffic, or replace
  /// delegates, so SSL Pinning and the host's session configuration remain untouched.
  public static func beginObservation(_ request: URLRequest) async -> TraceLensObservation? {
    let transactionID = UUID()
    let didBegin = await CaptureRuntime.shared.begin(id: transactionID, request: request)

    return didBegin ? TraceLensObservation(transactionID: transactionID) : nil
  }

  /// Records the final response received by the host networking stack.
  public static func recordResponse(
    _ response: URLResponse,
    body: Data,
    metrics: NetworkMetrics? = nil,
    for observation: TraceLensObservation
  ) async {
    await CaptureRuntime.shared.response(
      response,
      data: body,
      metrics: metrics,
      transactionID: observation.transactionID
    )
  }

  /// Records a failure produced by the host networking stack.
  public static func recordFailure(
    _ error: Error,
    for observation: TraceLensObservation,
    cancelled: Bool = false
  ) async {
    await CaptureRuntime.shared.failed(
      error,
      transactionID: observation.transactionID,
      cancelled: cancelled
    )
  }

  /// Records task metrics supplied by the host networking stack.
  public static func recordMetrics(
    _ metrics: NetworkMetrics,
    for observation: TraceLensObservation
  ) async {
    await CaptureRuntime.shared.record(metrics: metrics, transactionID: observation.transactionID)
  }

  // MARK: - URLSession Instrumentation

  /// Instruments a URLSessionConfiguration using URLProtocol.
  ///
  /// Use only with session stacks that do not own custom delegates, SSL Pinning, or other
  /// delegate-based transport behavior. SDCore integrations must use passive observation.
  public static func instrument(
    _ configuration: URLSessionConfiguration
  ) -> URLSessionConfiguration {
    URLSessionInstrumentation.instrument(configuration)
  }
}
