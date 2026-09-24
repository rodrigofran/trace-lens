@preconcurrency import Foundation
import TraceLensCore
import TraceLensStorage

public actor CaptureRuntime {
  // MARK: - Shared Instance

  public static let shared = CaptureRuntime()

  // MARK: - State

  private var store: SessionStore?
  private var bodies: TemporaryBodyStore?
  private var configuration: TraceLensConfiguration = .init()
  private var enabled = false

  // MARK: - Lifecycle

  public func start(
    configuration: TraceLensConfiguration,
    store: SessionStore,
    bodies: TemporaryBodyStore
  ) {
    self.configuration = configuration
    self.store = store
    self.bodies = bodies
    enabled = true
  }

  public func updateConfiguration(_ configuration: TraceLensConfiguration) {
    self.configuration = configuration
  }

  public func stop() {
    enabled = false
    store = nil
    bodies = nil
  }

  // MARK: - Capture

  @discardableResult
  public func begin(id: UUID, request: URLRequest) async -> Bool {
    guard enabled,
      configuration.captureNetworkTraffic,
      let url = request.url,
      let store
    else {
      return false
    }

    let method = HTTPMethod(request.httpMethod)
    let capture = await store.resolve(
      url: url,
      method: method,
      defaultCapture: configuration.defaultCapture
    )
    let parsed = EndpointParser(
      strategy: configuration.endpointPresentation,
      aliases: configuration.serviceAliases
    ).parse(url)
    let headers = capture.0 == .full ? (request.allHTTPHeaderFields ?? [:]) : [:]

    let savedBody: BodyReference =
      if capture.0 == .full, let data = request.httpBody, let bodies {
        await bodies.store(data, kind: "request")
      } else {
        .none
      }

    let transaction = NetworkTransaction(
      id: id,
      request: .init(
        url: url,
        method: method,
        parsed: parsed,
        headers: headers,
        body: savedBody,
        estimatedSize: request.httpBody?.count
      ),
      captureLevel: capture.0
    )

    return await store.begin(transaction)
  }

  public func response(
    _ response: URLResponse,
    data: Data,
    metrics: NetworkMetrics? = nil,
    transactionID: UUID
  ) async {
    guard let store,
      let transaction = await store.transaction(transactionID)
    else {
      return
    }

    let http = response as? HTTPURLResponse
    let body: BodyReference =
      if transaction.captureLevel == .full, let bodies {
        await bodies.store(data, kind: "response")
      } else {
        .none
      }
    let headers =
      transaction.captureLevel == .full
      ? (http?.allHeaderFields.reduce(into: [String: String]()) {
        $0[String(describing: $1.key)] = String(describing: $1.value)
      } ?? [:])
      : [:]
    let shouldRecordMetrics = configuration.captureTaskMetrics

    await store.update(transaction.id) { value in
      value.response = .init(
        statusCode: http?.statusCode ?? 0,
        headers: headers,
        body: body,
        mimeType: response.mimeType,
        expectedContentLength: response.expectedContentLength,
        capturedSize: data.count
      )
      value.error = nil

      if shouldRecordMetrics, let metrics {
        value.metrics = metrics
      }

      value.finishedAt = .now
      value.state = .completed
    }
  }

  // MARK: - Metrics

  public func record(metrics: NetworkMetrics, transactionID: UUID) async {
    guard configuration.captureTaskMetrics, let store else {
      return
    }

    await store.update(transactionID) { value in
      value.metrics = metrics
    }
  }

  // MARK: - Failures

  public func failed(
    _ error: Error,
    transactionID: UUID,
    cancelled: Bool = false
  ) async {
    guard let store,
      let transaction = await store.transaction(transactionID),
      transaction.state != .completed
    else {
      return
    }

    await store.update(transactionID) { value in
      value.error = NetworkError(error)
      value.finishedAt = .now
      value.state = cancelled ? .cancelled : .failed
    }
  }
}
