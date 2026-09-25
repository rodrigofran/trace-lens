import SwiftUI

struct RequestSortMenu: View {
  // MARK: - Dependencies

  @ObservedObject var model: TraceLensViewModel

  // MARK: - View

  var body: some View {
    Menu {
      ForEach(RequestSortOrder.allCases) { order in
        Button {
          model.sortOrder = order
        } label: {
          Label(
            order.title,
            systemImage: model.sortOrder == order ? "checkmark" : order.icon
          )
        }
      }
    } label: {
      Label(model.sortOrder.title, systemImage: model.sortOrder.icon)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(DashboardColor.secondaryGroupedBackground, in: Capsule())
    }
  }
}
