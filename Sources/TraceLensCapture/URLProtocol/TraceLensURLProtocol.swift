@preconcurrency import Foundation
import TraceLensCore

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
    guard let url = request.url else {
      return
    }

    let mutable = NSMutableURLRequest(url: url)

    if let method = request.httpMethod {
      mutable.httpMethod = method
    }

    mutable.httpBody = request.httpBody

    for (key, value) in request.allHTTPHeaderFields ?? [:] {
      mutable.setValue(value, forHTTPHeaderField: key)
    }

    URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutable)

    let request = mutable as URLRequest
    let id = transactionID

    Task {
      await CaptureRuntime.shared.begin(id: id, request: request)
    }

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = (configuration.protocolClasses ?? []).filter {
      $0 != TraceLensURLProtocol.self
    }

    let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    forwardingTask = session.dataTask(with: request)
    forwardingTask?.resume()
  }

  public override func stopLoading() {
    forwardingTask?.cancel()

    let id = transactionID

    Task {
      await CaptureRuntime.shared.failed(
        URLError(.cancelled),
        transactionID: id,
        cancelled: true
      )
    }
  }

  // MARK: - URLSessionDataDelegate

  public func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    didReceive response: URLResponse,
    completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
  ) {
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    completionHandler(.allow)
  }

  public func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    didReceive data: Data
  ) {
    self.data.append(data)
    client?.urlProtocol(self, didLoad: data)
  }

  public func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didCompleteWithError error: Error?
  ) {
    let id = transactionID

    if let error {
      client?.urlProtocol(self, didFailWithError: error)

      Task {
        await CaptureRuntime.shared.failed(error, transactionID: id)
      }
    } else if let response = task.response {
      let captured = data

      client?.urlProtocolDidFinishLoading(self)

      Task {
        await CaptureRuntime.shared.response(response, data: captured, transactionID: id)
      }
    }
  }
}
