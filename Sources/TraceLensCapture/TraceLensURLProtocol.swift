@preconcurrency import Foundation
import TraceLensCore
import TraceLensStorage

public actor CaptureRuntime {
  // MARK: - Shared instance

  public static let shared = CaptureRuntime()

  // MARK: - State

  private var store: SessionStore?
  private var bodies: TemporaryBodyStore?
  private var configuration: TraceLensConfiguration = .init()
  private var enabled = false

  // MARK: - Lifecycle

  public func start(
    configuration: TraceLensConfiguration, store: SessionStore, bodies: TemporaryBodyStore
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
      url: url, method: method, defaultCapture: configuration.defaultCapture)

    let parsed = EndpointParser(
      strategy: configuration.endpointPresentation, aliases: configuration.serviceAliases
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
    guard configuration.captureTaskMetrics, let store else { return }

    await store.update(transactionID) { value in
      value.metrics = metrics
    }
  }

  // MARK: - Failures

  public func failed(_ error: Error, transactionID: UUID, cancelled: Bool = false) async {
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

/// URLProtocol is an Objective-C callback API. This narrow unchecked conformance is
/// required by Foundation's imported URLProtocol declaration; mutable state is only
/// touched by its URLSession delegate callbacks for a single protocol instance.
public final class TraceLensURLProtocol: URLProtocol, URLSessionDataDelegate, @unchecked Sendable {
  // MARK: - State

  private static let handledKey = "com.tracelens.handled"
  private var forwardingTask: URLSessionDataTask?
  private var data = Data()
  private let transactionID = UUID()

  // MARK: - URLProtocol

  public override class func canInit(with request: URLRequest) -> Bool {
    guard let scheme = request.url?.scheme?.lowercased(),
      scheme == "http" || scheme == "https"
    else {
      return false
    }

    return URLProtocol.property(forKey: handledKey, in: request) == nil
  }

  public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  public override func startLoading() {
    guard let url = self.request.url else {
      return
    }

    let mutable = NSMutableURLRequest(url: url)

    if let method = self.request.httpMethod { mutable.httpMethod = method }

    mutable.httpBody = self.request.httpBody

    for (key, value) in self.request.allHTTPHeaderFields ?? [:] {
      mutable.setValue(value, forHTTPHeaderField: key)
    }

    URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutable)

    let request = mutable as URLRequest
    let id = transactionID

    Task {
      await CaptureRuntime.shared.begin(id: id, request: request)
    }

    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = (config.protocolClasses ?? []).filter {
      $0 != TraceLensURLProtocol.self
    }

    let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

    forwardingTask = session.dataTask(with: request)
    forwardingTask?.resume()
  }

  public override func stopLoading() {
    forwardingTask?.cancel()
    let id = transactionID
    Task {
      await CaptureRuntime.shared.failed(URLError(.cancelled), transactionID: id, cancelled: true)
    }
  }

  // MARK: - URLSessionDataDelegate

  public func urlSession(
    _ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
    completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
  ) {
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    completionHandler(.allow)
  }

  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
  {
    self.data.append(data)
    client?.urlProtocol(self, didLoad: data)
  }

  public func urlSession(
    _ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?
  ) {
    let id = transactionID
    if let error {
      client?.urlProtocol(self, didFailWithError: error)

      Task {
        await CaptureRuntime.shared.failed(error, transactionID: id)
      }
    } else if let response = task.response {
      let captured = self.data

      client?.urlProtocolDidFinishLoading(self)

      Task {
        await CaptureRuntime.shared.response(response, data: captured, transactionID: id)
      }
    }
  }
}

public enum URLSessionInstrumentation {
  // MARK: - Public API

  public static func instrument(_ configuration: URLSessionConfiguration) -> URLSessionConfiguration
  {
    let copy = configuration.copy() as! URLSessionConfiguration

    guard copy.identifier == nil else {
      return copy
    }

    var classes = copy.protocolClasses ?? []

    if !classes.contains(where: { $0 == TraceLensURLProtocol.self }) {
      classes.insert(TraceLensURLProtocol.self, at: 0)
    }

    copy.protocolClasses = classes

    return copy
  }
}
