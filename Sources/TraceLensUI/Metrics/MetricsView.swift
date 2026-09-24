import SwiftUI
import TraceLensMetrics

struct MetricsScreen: View {
  @ObservedObject var model: TraceLensViewModel
  let onClose: (() -> Void)?
  var body: some View {
    let values = MetricsAggregator().aggregate(model.snapshot?.transactions ?? [])
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          DashboardHeader(title: "Métricas", subtitle: "Uma visão clara desta sessão.")
          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(title: "Requests", value: String(values.totalRequests))
            MetricTile(
              title: "Duração média",
              value: values.averageDuration.map { String(format: "%.0f ms", $0 * 1000) } ?? "—")
            MetricTile(
              title: "Taxa de erros", value: String(format: "%.1f%%", values.errorRate * 100))
            MetricTile(
              title: "Detalhes completos",
              value: String(format: "%.0f%%", values.fullCaptureRatio * 100))
          }
          VStack(alignment: .leading, spacing: 9) {
            Text("Serviços mais acessados").font(.headline).foregroundStyle(.secondary)
            ForEach(values.services, id: \.service) { service in
              HStack(spacing: 12) {
                SettingsRowIcon(name: "network")
                VStack(alignment: .leading, spacing: 2) {
                  Text(service.service).font(.body.weight(.medium))
                  Text("\(service.requestCount) requests").font(.caption).foregroundStyle(
                    .secondary)
                }
                Spacer()
              }
              .padding(12)
              .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            }
          }
        }
        .padding(20)
      }
      .traceLensBackground()
      .traceLensInlineNavigationTitle()
      .traceLensCloseToolbar(onClose)
    }
    .traceLensNavigationStyle()
  }
}

private struct MetricTile: View {
  let title: String
  let value: String
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.title3.bold())
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
  }
}
