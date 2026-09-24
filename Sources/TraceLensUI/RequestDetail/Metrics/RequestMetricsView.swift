import Foundation
import SwiftUI
import TraceLensCore

struct RequestMetricsView: View {
  // MARK: - Properties

  let transaction: NetworkTransaction

  // MARK: - View

  var body: some View {
    List {
      Section("Tempo") {
        ForEach(timings, id: \.name) { item in
          DetailValueRow(
            item.name,
            value: String(format: "%.0f ms", item.value * 1000)
          )
        }
      }

      if hasTransferDetails {
        Section("Transferência") {
          if let requestSize = transaction.request.estimatedSize {
            DetailValueRow("Body da request", value: byteCount(requestSize))
          }

          if let response = transaction.response {
            DetailValueRow("Body da response", value: byteCount(response.capturedSize))

            if let expectedContentLength = response.expectedContentLength,
              expectedContentLength >= 0
            {
              DetailValueRow(
                "Tamanho informado",
                value: byteCount(Int(expectedContentLength))
              )
            }
          }
        }
      }

      if hasConnectionDetails {
        Section("Conexão") {
          if let protocolName = transaction.metrics?.protocolName {
            DetailValueRow("Protocolo", value: protocolName)
          }

          if let reusedConnection = transaction.metrics?.reusedConnection {
            DetailValueRow("Conexão reutilizada", value: reusedConnection ? "Sim" : "Não")
          }

          if let redirects = transaction.metrics?.redirectCount, redirects > 0 {
            DetailValueRow("Redirecionamentos", value: String(redirects))
          }
        }
      }
    }
  }

  // MARK: - Derived State

  private var timings: [(name: String, value: TimeInterval)] {
    [
      ("Total", transaction.metrics?.total ?? transaction.duration),
      ("DNS", transaction.metrics?.dns),
      ("TCP", transaction.metrics?.tcp),
      ("TLS", transaction.metrics?.tls),
      ("Upload", transaction.metrics?.upload),
      ("TTFB", transaction.metrics?.firstByte),
      ("Download", transaction.metrics?.download),
    ]
    .compactMap { name, value in
      value.map { (name: name, value: $0) }
    }
  }

  private var hasTransferDetails: Bool {
    transaction.request.estimatedSize != nil || transaction.response != nil
  }

  private var hasConnectionDetails: Bool {
    let metrics = transaction.metrics

    return metrics?.protocolName != nil
      || metrics?.reusedConnection != nil
      || (metrics?.redirectCount ?? 0) > 0
  }

  // MARK: - Helpers

  private func byteCount(_ value: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
  }
}
