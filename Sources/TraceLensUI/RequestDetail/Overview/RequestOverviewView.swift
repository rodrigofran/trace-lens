import SwiftUI
import TraceLensCore

#if os(iOS) || os(tvOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

struct RequestOverviewView: View {
  // MARK: - Properties

  let transaction: NetworkTransaction

  // MARK: - View

  var body: some View {
    List {
      Section("Request") {
        DetailValueRow("Serviço", value: transaction.request.parsed.displayService ?? "—")
        DetailValueRow("Serviço técnico", value: transaction.request.parsed.technicalService ?? "—")
        DetailValueRow("Endpoint", value: transaction.request.parsed.endpoint)
        DetailValueRow("Host", value: transaction.request.parsed.host)
        DetailValueRow("Método", value: transaction.request.method.rawValue)
      }

      Section("URL completa") {
        Text(transaction.request.parsed.fullURL)
          .textSelection(.enabled)

        Button {
          copyToPasteboard(transaction.request.parsed.fullURL)
        } label: {
          Label("Copiar URL", systemImage: "doc.on.doc")
        }
      }

      Section("Status") {
        DetailValueRow("Status", value: transaction.response.map { String($0.statusCode) } ?? "—")
        DetailValueRow("Captura", value: transaction.captureLevel.rawValue.capitalized)
      }
    }
  }

  // MARK: - Helpers

  private func copyToPasteboard(_ value: String) {
    #if os(iOS) || os(tvOS) || os(visionOS)
      UIPasteboard.general.string = value
    #elseif os(macOS)
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(value, forType: .string)
    #endif
  }
}
