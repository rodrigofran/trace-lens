import SwiftUI

struct EmptyRequestsView: View {
  // MARK: - Properties

  let hasFilters: Bool

  // MARK: - View

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: hasFilters ? "line.3.horizontal.decrease.circle" : "network")
        .font(.system(size: 34))
        .foregroundStyle(.secondary)

      Text(hasFilters ? "Nenhuma request encontrada" : "Ainda não há requests")
        .font(.headline)

      Text(message)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(.top, 48)
    .padding(.horizontal, 24)
  }

  // MARK: - Derived State

  private var message: String {
    hasFilters
      ? "Ajuste a busca ou os filtros para ver o tráfego capturado."
      : "As requests de rede observadas nesta sessão aparecerão aqui."
  }
}
