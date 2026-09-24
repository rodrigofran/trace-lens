import SwiftUI
import TraceLensCore

struct TransactionRow: View {
  // MARK: - Properties

  let transaction: NetworkTransaction

  // MARK: - View

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      RoundedRectangle(cornerRadius: 3)
        .fill(transaction.request.method.traceColor)
        .frame(width: 5)

      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          methodBadge

          Text(transaction.request.parsed.displayService ?? transaction.request.parsed.endpoint)
            .font(.headline)
            .lineLimit(1)

          Spacer(minLength: 8)

          Text(status)
            .font(.subheadline.bold())
            .foregroundStyle(statusColor)
        }

        HStack(alignment: .top, spacing: 8) {
          VStack(alignment: .leading, spacing: 3) {
            Text(transaction.request.parsed.endpoint)
              .font(.subheadline)
              .foregroundStyle(.primary)
              .lineLimit(1)

            Text(transaction.request.parsed.fullURL)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }

          Spacer(minLength: 8)

          VStack(alignment: .trailing, spacing: 3) {
            Text(duration)
            Text(transaction.captureLevel == .full ? "Completo" : "Metadata")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(DashboardColor.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 10))
  }

  // MARK: - Components

  private var methodBadge: some View {
    Text(transaction.request.method.rawValue)
      .font(.caption.bold())
      .foregroundStyle(transaction.request.method.traceColor)
      .padding(.horizontal, 9)
      .frame(height: 26)
      .background(
        transaction.request.method.traceColor.opacity(0.14),
        in: RoundedRectangle(cornerRadius: 6)
      )
  }

  // MARK: - Derived State

  private var duration: String {
    transaction.duration.map { String(format: "%.0f ms", $0 * 1000) } ?? "Em andamento"
  }

  private var status: String {
    transaction.response.map { String($0.statusCode) }
      ?? (transaction.error == nil ? "Em andamento" : "Erro")
  }

  private var statusColor: Color {
    if transaction.error != nil {
      return .red
    }

    guard let code = transaction.response?.statusCode else {
      return .secondary
    }

    if code >= 500 {
      return .red
    }

    if code >= 400 {
      return .orange
    }

    if code >= 200 && code < 300 {
      return .green
    }

    return .secondary
  }
}
