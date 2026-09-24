import Foundation
import TraceLensCore

public enum CurlExporter {
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

  // MARK: - Helpers

  private static func shellQuote(_ value: String) -> String {
    "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
  }
}
