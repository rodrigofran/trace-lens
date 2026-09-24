import SwiftUI
import TraceLensCore

struct RequestsScreen: View {
  // MARK: - Dependencies

  @ObservedObject var model: TraceLensViewModel

  let policy: SensitiveDataPolicy
  let onClose: (() -> Void)?

  // MARK: - View

  var body: some View {
    NavigationView {
      ScrollView {
        LazyVStack(spacing: 12) {
          DashboardHeader(title: "TraceLens", subtitle: "\(model.totalTransactions) requests")
          RequestSearchBar(text: $model.search)
          RequestFilterBar(model: model)

          if model.transactions.isEmpty {
            EmptyRequestsView(hasFilters: hasActiveFilters)
          } else {
            ForEach(model.transactions) { transaction in
              NavigationLink(destination: RequestDetail(transaction: transaction, policy: policy)) {
                TransactionRow(transaction: transaction)
              }
              .buttonStyle(.plain)
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

  // MARK: - Derived State

  private var hasActiveFilters: Bool {
    !model.search.isEmpty
      || model.method != nil
      || model.capture != nil
      || model.statusFilter != .all
  }
}
