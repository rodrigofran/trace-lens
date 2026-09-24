import Foundation

public enum SensitiveData {
  // MARK: - Redaction

  public static func value(
    _ value: String,
    key: String,
    policy: SensitiveDataPolicy
  ) -> String {
    guard policy == .redacted else {
      return value
    }

    let lower = key.lowercased()
    let sensitiveKeys = [
      "authorization",
      "cookie",
      "set-cookie",
      "token",
      "password",
      "secret",
      "api-key",
      "x-api-key",
    ]

    return sensitiveKeys.contains(where: lower.contains) ? "••••••••" : value
  }

  public static func headers(
    _ headers: [String: String],
    policy: SensitiveDataPolicy
  ) -> [String: String] {
    Dictionary(
      uniqueKeysWithValues: headers.map {
        ($0.key, value($0.value, key: $0.key, policy: policy))
      }
    )
  }
}
