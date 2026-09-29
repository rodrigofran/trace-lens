import Foundation
import TraceLensCore

public enum CurlExporter {
  public enum Error: LocalizedError, Equatable {
    case incompleteCapture
    case missingComponent
    case missingBearerToken
    case invalidDestination

    public var errorDescription: String? {
      switch self {
      case .incompleteCapture:
        "A request precisa ter sido capturada com detalhes completos."
      case .missingComponent:
        "Não foi possível identificar o componente da rota."
      case .missingBearerToken:
        "A request não contém um Bearer token."
      case .invalidDestination:
        "Não foi possível montar a URL do BFF."
      }
    }
  }

  // MARK: - Public API

  public static func command(
    for transaction: NetworkTransaction,
    policy: SensitiveDataPolicy
  ) -> String? {
    guard transaction.captureLevel == .full else {
      return nil
    }

    var parts = [
      "curl",
      "-X",
      transaction.request.method.rawValue,
      shellQuote(transaction.request.url.absoluteString),
    ]

    for (key, value) in SensitiveData.headers(
      transaction.request.headers,
      policy: policy
    ).sorted(by: { $0.key < $1.key }) {
      parts += ["-H", shellQuote("\(key): \(value)")]
    }

    if policy == .visible,
      case .inline = transaction.request.body.storage,
      let data = transaction.request.body.data,
      let body = String(data: data, encoding: .utf8)
    {
      parts += ["--data-raw", shellQuote(body)]
    }

    return parts.joined(separator: " ")
  }

  /// Creates a command that calls the BFF directly, bypassing the gateway route.
  /// The original bearer token is intentionally retained so the command can be run.
  public static func bffCommand(
    for transaction: NetworkTransaction,
    bodyData: Data?,
    destination: CurlBFFDestination
  ) throws -> String {
    guard transaction.captureLevel == .full else {
      throw Error.incompleteCapture
    }

    guard let authorization = transaction.request.headers.first(where: {
      $0.key.caseInsensitiveCompare("Authorization") == .orderedSame
    })?.value,
      authorization.trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased().hasPrefix("bearer ")
    else {
      throw Error.missingBearerToken
    }

    guard let component = transaction.request.parsed.technicalService,
      !component.isEmpty
    else {
      throw Error.missingComponent
    }

    guard let url = bffURL(
      endpoint: transaction.request.parsed.endpoint,
      originalURL: transaction.request.url,
      destination: destination
    ) else {
      throw Error.invalidDestination
    }

    var parts = ["curl", "-X", transaction.request.method.rawValue, shellQuote(url.absoluteString)]
    let excludedHeaders = ["host", "content-length"]

    for (key, value) in transaction.request.headers.sorted(by: { $0.key < $1.key })
      where !excludedHeaders.contains(key.lowercased())
    {
      parts += ["-H", shellQuote("\(key): \(value)")]
    }

    if let bodyData, let body = String(data: bodyData, encoding: .utf8) {
      parts += ["--data-raw", shellQuote(body)]
    }

    return parts.joined(separator: " ")
  }

  // MARK: - Helpers

  private static func shellQuote(_ value: String) -> String {
    "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
  }

  private static func bffURL(
    endpoint: String,
    originalURL: URL,
    destination: CurlBFFDestination
  ) -> URL? {
    var components = URLComponents()
    let destinationHost = destination.host.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !destinationHost.isEmpty else { return nil }

    if destinationHost.lowercased() == "localhost"
      || destinationHost.lowercased().hasPrefix("localhost:")
    {
      let localhost = URLComponents(string: "http://\(destinationHost)")
      guard localhost?.host?.lowercased() == "localhost" else { return nil }
      components.scheme = "http"
      components.host = "localhost"
      components.port = localhost?.port
    } else {
      components.scheme = "https"
      components.host = destinationHost
    }
    components.percentEncodedPath = combinedPath(
      destination.intermediatePath,
      endpoint
    )
    components.percentEncodedQuery = URLComponents(
      url: originalURL,
      resolvingAgainstBaseURL: false
    )?.percentEncodedQuery
    return components.url
  }

  private static func combinedPath(_ intermediatePath: String, _ endpoint: String) -> String {
    let prefix = intermediatePath.trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let destination = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let segments = [prefix, destination].filter { !$0.isEmpty }
    return "/" + segments.joined(separator: "/")
  }
}
