import SwiftUI

struct HeaderValueRow: View {
  // MARK: - Properties

  let title: String
  let value: String

  // MARK: - View

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      Text(value)
        .font(.system(.body, design: .monospaced))
        .foregroundStyle(.primary)
        .textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 4)
  }
}
