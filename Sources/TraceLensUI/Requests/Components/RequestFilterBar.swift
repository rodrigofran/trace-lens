import SwiftUI
import TraceLensCore

struct RequestFilterBar: View {
  // MARK: - Dependencies

  @ObservedObject var model: TraceLensViewModel

  // MARK: - View

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        FilterChip(title: "Todas", isSelected: model.statusFilter == .all && model.capture == nil) {
          model.statusFilter = .all
          model.capture = nil
        }

        FilterChip(title: "Erros", isSelected: model.statusFilter == .errors) {
          model.statusFilter = model.statusFilter == .errors ? .all : .errors
        }

        FilterChip(title: "Detalhes completos", isSelected: model.capture == .full) {
          model.capture = model.capture == .full ? nil : .full
        }

        ForEach(HTTPMethod.allCases.filter { $0 != .other }, id: \.self) { method in
          MethodFilterChip(method: method, isSelected: model.method == method) {
            model.method = model.method == method ? nil : method
          }
        }
      }
      .padding(.vertical, 2)
    }
  }
}

private struct FilterChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.caption.bold())
        .foregroundStyle(isSelected ? .white : .primary)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(
          isSelected ? Color.green : DashboardColor.secondaryGroupedBackground,
          in: Capsule()
        )
    }
    .buttonStyle(.plain)
  }
}

private struct MethodFilterChip: View {
  let method: HTTPMethod
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(method.rawValue)
        .font(.caption.bold())
        .foregroundStyle(isSelected ? .white : method.traceColor)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(
          isSelected ? method.traceColor : method.traceColor.opacity(0.14),
          in: Capsule()
        )
    }
    .buttonStyle(.plain)
  }
}
