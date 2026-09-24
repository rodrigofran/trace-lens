import SwiftUI

struct RequestSearchBar: View {
  // MARK: - Properties

  @Binding var text: String

  // MARK: - View

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)

      TextField("Buscar requests, serviços ou hosts...", text: $text)
        .autocorrectionDisabled()

      if !text.isEmpty {
        Button {
          text = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      }
    }
    .font(.subheadline)
    .padding(.horizontal, 12)
    .padding(.vertical, 11)
    .background(DashboardColor.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 10))
  }
}
