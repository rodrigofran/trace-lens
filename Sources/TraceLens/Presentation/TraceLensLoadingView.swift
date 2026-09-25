import SwiftUI

struct TraceLensLoadingView: View {
  // MARK: - Properties

  let onClose: () -> Void

  // MARK: - View

  var body: some View {
    ZStack {
      Color.black.opacity(0.035)
        .ignoresSafeArea()

      VStack(spacing: 16) {
        Image(systemName: "cube.transparent.fill")
          .font(.system(size: 38, weight: .medium))
          .foregroundStyle(.white)
          .frame(width: 76, height: 76)
          .background(.green, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

        Text("TraceLens")
          .font(.title.bold())

        ProgressView()
          .tint(.green)

        Text("Carregando sessão...")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .overlay(alignment: .topTrailing) {
      Button(action: onClose) {
        Image(systemName: "xmark")
          .font(.headline.weight(.bold))
          .foregroundStyle(.primary)
          .frame(width: 44, height: 44)
          .background(.ultraThinMaterial, in: Circle())
      }
      .padding(.top, 16)
      .padding(.trailing, 20)
    }
  }
}
