#if os(iOS)
  import SwiftUI
  import UIKit

  @MainActor
  final class TraceLensUIKitPresenter {
    // MARK: - Shared Instance

    static let shared = TraceLensUIKitPresenter()

    // MARK: - State

    private weak var presentedViewController: UIViewController?

    // MARK: - Presentation

    func show() {
      guard let rootViewController = activeRootViewController() else {
        return
      }

      show(from: rootViewController)
    }

    func show(from viewController: UIViewController) {
      guard presentedViewController == nil else {
        return
      }

      let presenter = topViewController(from: viewController)
      let hostingController = UIHostingController(rootView: TraceLensView())

      hostingController.modalPresentationStyle = .fullScreen
      hostingController.rootView = TraceLensView { [weak self, weak hostingController] in
        hostingController?.dismiss(animated: true)
        self?.presentedViewController = nil
      }

      presentedViewController = hostingController
      presenter.present(hostingController, animated: true)
    }

    func hide() {
      presentedViewController?.dismiss(animated: true)
      presentedViewController = nil
    }

    // MARK: - View Controller Resolution

    private func activeRootViewController() -> UIViewController? {
      let scenes = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .filter { $0.activationState == .foregroundActive }
      let windows = scenes.flatMap(\.windows)

      return windows.first(where: \.isKeyWindow)?.rootViewController
        ?? windows.first?.rootViewController
    }

    private func topViewController(from viewController: UIViewController) -> UIViewController {
      if let presentedViewController = viewController.presentedViewController {
        return topViewController(from: presentedViewController)
      }

      if let navigationController = viewController as? UINavigationController,
        let visibleViewController = navigationController.visibleViewController
      {
        return topViewController(from: visibleViewController)
      }

      if let tabBarController = viewController as? UITabBarController,
        let selectedViewController = tabBarController.selectedViewController
      {
        return topViewController(from: selectedViewController)
      }

      return viewController
    }
  }
#endif
