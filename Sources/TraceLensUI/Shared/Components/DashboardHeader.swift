import SwiftUI

struct DashboardHeader: View {
  // MARK: - Properties

  let title: String
  let subtitle: String

  // MARK: - View

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: iconName)
        .font(.title2.weight(.semibold))
        .foregroundStyle(.white)
        .frame(width: 50, height: 50)
        .background(
          LinearGradient(
            colors: [.green, Color.green.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          in: RoundedRectangle(cornerRadius: 16)
        )

      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.title.bold())
        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()
      LiveBadge()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Private Methods

  private var iconName: String {
    switch title {
    case "Métricas":
      "chart.bar.xaxis"
    case "Escopos":
      "scope"
    default:
      "cube.transparent.fill"
    }
  }
}

struct LiveBadge: View {
  // MARK: - View

  var body: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(Color.green)
        .frame(width: 8, height: 8)

      Text("Ativo")
        .font(.caption.bold())
    }
    .foregroundStyle(.green)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Color.green.opacity(0.12), in: Capsule())
  }
}
