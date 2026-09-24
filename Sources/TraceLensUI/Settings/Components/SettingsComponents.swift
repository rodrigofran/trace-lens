import SwiftUI

struct SettingsHeader: View {
  // MARK: - View

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: "cube.transparent.fill")
        .font(.title)
        .foregroundStyle(.white)
        .frame(width: 52, height: 52)
        .background(
          LinearGradient(
            colors: [.green, Color.green.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          in: RoundedRectangle(cornerRadius: 16)
        )

      VStack(alignment: .leading, spacing: 2) {
        Text("TraceLens")
          .font(.title.bold())
        Text("Ajustes")
          .font(.title3)
          .foregroundStyle(.secondary)
      }

      Spacer()
      LiveBadge()
    }
  }
}

struct SettingsSection<Content: View>: View {
  // MARK: - Properties

  let title: String

  @ViewBuilder let content: Content

  // MARK: - View

  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      Text(title)
        .font(.headline)
        .foregroundStyle(.secondary)

      VStack(spacing: 0) {
        content
      }
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
  }
}

struct SettingsRowIcon: View {
  // MARK: - Properties

  let name: String
  var tint: Color = .green

  // MARK: - View

  var body: some View {
    Image(systemName: name)
      .font(.title3.weight(.medium))
      .foregroundStyle(tint)
      .frame(width: 48, height: 48)
      .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
  }
}

struct SettingsToggleRow: View {
  // MARK: - Properties

  let icon: String
  let title: String
  let isOn: Binding<Bool>

  // MARK: - View

  var body: some View {
    HStack(spacing: 14) {
      SettingsRowIcon(name: icon)
      Text(title)
        .font(.body.weight(.medium))
      Spacer()
      Toggle(title, isOn: isOn)
        .labelsHidden()
        .tint(.green)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .settingsDivider()
  }
}

struct SettingsMenuRow<Content: View>: View {
  // MARK: - Properties

  let icon: String
  let title: String
  let value: String

  @ViewBuilder let menu: Content

  // MARK: - View

  var body: some View {
    HStack(spacing: 14) {
      SettingsRowIcon(name: icon)
      Text(title)
        .font(.body.weight(.medium))
      Spacer()

      Menu {
        menu
      } label: {
        HStack(spacing: 5) {
          Text(value)
            .foregroundStyle(.secondary)
          Image(systemName: "chevron.right")
            .font(.caption.weight(.bold))
            .foregroundStyle(.tertiary)
        }
      }
      .tint(.primary)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .settingsDivider()
  }
}

struct SettingsValueRow: View {
  // MARK: - Properties

  let icon: String
  let title: String
  let value: String

  var tint: Color = .green
  var isDestructive = false
  var showsDisclosure = false
  var showsDivider = true

  // MARK: - View

  var body: some View {
    HStack(spacing: 14) {
      SettingsRowIcon(name: icon, tint: tint)
      Text(title)
        .font(.body.weight(.medium))
        .foregroundStyle(isDestructive ? .red : .primary)
      Spacer()

      if !value.isEmpty {
        Text(value)
          .foregroundStyle(.secondary)
      }

      if showsDisclosure {
        Image(systemName: "chevron.right")
          .font(.caption.weight(.bold))
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .settingsDivider(showsDivider)
  }
}

struct TraceLensToast: View {
  // MARK: - Properties

  let message: String

  // MARK: - View

  var body: some View {
    Label(message, systemImage: "checkmark.circle.fill")
      .font(.subheadline.weight(.medium))
      .foregroundStyle(.white)
      .padding(.horizontal, 16)
      .padding(.vertical, 11)
      .background(.green, in: Capsule())
      .shadow(color: .black.opacity(0.16), radius: 12, y: 5)
      .transition(.move(edge: .top).combined(with: .opacity))
  }
}

struct SettingsStepperRow: View {
  // MARK: - Properties

  let icon: String
  let title: String
  let value: Binding<Int>

  // MARK: - View

  var body: some View {
    HStack(spacing: 14) {
      SettingsRowIcon(name: icon)
      Text(title)
        .font(.body.weight(.medium))
      Spacer()

      Stepper(value: value, in: 100...10_000, step: 100) {
        Text(value.wrappedValue.formatted())
          .monospacedDigit()
      }
      .labelsHidden()
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .settingsDivider()
  }
}
