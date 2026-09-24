import SwiftUI

struct DetailValueRow: View {
  // MARK: - Properties

  let title: String
  let value: String

  // MARK: - Initialization

  init(_ title: String, value: String) {
    self.title = title
    self.value = value
  }

  // MARK: - View

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 16) {
      Text(title)
        .foregroundStyle(.primary)

      Spacer(minLength: 12)

      Text(value)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.trailing)
        .lineLimit(nil)
    }
  }
}
