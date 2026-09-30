import Foundation
import TraceLensCore
import TraceLensStorage

enum SessionTextExporter {
  static func export(
    snapshot: SessionSnapshot,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?
  ) async throws -> URL {
    var sections = [
      "TraceLens, Sessão",
      "ID: \(snapshot.session.id.uuidString)",
      "Iniciada em: \(formatted(snapshot.session.startedAt))",
      "Exportada em: \(formatted(.now))",
      "Total de requests: \(snapshot.transactions.count)",
    ]

    for (index, transaction) in snapshot.transactions.enumerated() {
      sections.append(await text(for: transaction, configuration: configuration, bodies: bodies, title: "Request \(index + 1)"))
    }

    return try ExportFileWriter.writeText(
      sections.joined(separator: "\n\n\(String(repeating: "=", count: 72))\n\n"),
      named: "tracelens-session-\(snapshot.session.id.uuidString)-\(ExportFileWriter.timestamp()).txt"
    )
  }

  static func export(
    _ transaction: NetworkTransaction,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?
  ) async throws -> URL {
    try ExportFileWriter.writeText(
      await text(for: transaction, configuration: configuration, bodies: bodies, title: "TraceLens, Request"),
      named: "tracelens-request-\(transaction.id.uuidString)-\(ExportFileWriter.timestamp()).txt"
    )
  }

  private static func text(
    for transaction: NetworkTransaction,
    configuration: TraceLensConfiguration,
    bodies: TemporaryBodyStore?,
    title: String
  ) async -> String {
    let requestHeaders = SensitiveData.headers(transaction.request.headers, policy: configuration.sensitiveDataPolicy)
    let requestBody = await bodyText(transaction.request.body, contentType: contentType(in: transaction.request.headers), bodies: bodies)
    let responseHeaders = transaction.response.map { SensitiveData.headers($0.headers, policy: configuration.sensitiveDataPolicy) } ?? [:]
    let responseBody = await bodyText(transaction.response?.body ?? .none, contentType: transaction.response?.mimeType ?? contentType(in: transaction.response?.headers ?? [:]), bodies: bodies)

    var lines = [
      title, "ID: \(transaction.id.uuidString)", "Estado: \(transaction.state.rawValue)",
      "Captura: \(transaction.captureLevel.rawValue)", "Iniciada em: \(formatted(transaction.startedAt))",
      "Finalizada em: \(transaction.finishedAt.map(formatted) ?? "Não informado")", "", "REQUEST",
      "\(transaction.request.method.rawValue) \(transaction.request.parsed.fullURL)",
      "Serviço: \(transaction.request.parsed.displayService ?? "Não informado")",
      "Serviço técnico: \(transaction.request.parsed.technicalService ?? "Não informado")", "Headers:",
      headerText(requestHeaders), "Body:", requestBody, "", "RESPONSE",
      "Status: \(transaction.response.map { String($0.statusCode) } ?? "Não informado")", "Headers:",
      headerText(responseHeaders), "Body:", responseBody,
    ]

    if let metrics = transaction.metrics {
      lines += ["", "MÉTRICAS", "Total: \(milliseconds(metrics.total))", "DNS: \(milliseconds(metrics.dns))", "TCP: \(milliseconds(metrics.tcp))", "TLS: \(milliseconds(metrics.tls))", "Primeiro byte: \(milliseconds(metrics.firstByte))", "Download: \(milliseconds(metrics.download))"]
    }
    if let error = transaction.error { lines += ["", "ERRO", "\(error.domain) (\(error.code)): \(error.message)"] }
    return lines.joined(separator: "\n")
  }

  private static func bodyText(_ reference: BodyReference, contentType: String?, bodies: TemporaryBodyStore?) async -> String {
    let data: Data?
    switch reference.storage {
    case .inline: data = reference.data
    case .file: data = await bodies?.data(for: reference)
    case .none: return "Não capturado."
    case .truncated: return "Truncado. Tamanho original: \(reference.originalSize ?? 0) bytes."
    }
    guard let data else { return "Indisponível." }
    guard let text = String(data: data, encoding: .utf8) else { return "Conteúdo binário em Base64:\n\(data.base64EncodedString())" }
    return prettyPrinted(text, contentType: contentType)
  }

  private static func prettyPrinted(_ text: String, contentType: String?) -> String {
    guard contentType?.lowercased().contains("json") ?? true, let data = text.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data), let formatted = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]), let result = String(data: formatted, encoding: .utf8) else { return text }
    return result
  }
  private static func headerText(_ headers: [String: String]) -> String { headers.isEmpty ? "Não informado" : headers.sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }.map { "\($0.key): \($0.value)" }.joined(separator: "\n") }
  private static func milliseconds(_ value: TimeInterval?) -> String { value.map { "\(Int(($0 * 1_000).rounded())) ms" } ?? "Não informado" }
  private static func formatted(_ date: Date) -> String { ISO8601DateFormatter().string(from: date) }
}
