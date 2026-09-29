import Foundation

enum ExportFileWriter {
  static func write<T: Encodable>(_ value: T, named fileName: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    encoder.dateEncodingStrategy = .iso8601
    try encoder.encode(value).write(to: url, options: .atomic)
    return url
  }

  static func writeText(_ value: String, named fileName: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    try value.write(to: url, atomically: true, encoding: .utf8)
    return url
  }

  static func timestamp() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd-HHmmss"
    return formatter.string(from: .now)
  }
}
