#if os(iOS)
  import SwiftUI
  import UIKit

  @MainActor
  final class TraceLensUIKitPresenter: NSObject, UIAdaptivePresentationControllerDelegate {
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
      let isPresentedOverSheet = presenter.presentationController is UISheetPresentationController

      configurePresentation(
        for: hostingController,
        presentedOverSheet: isPresentedOverSheet
      )
      hostingController.presentationController?.delegate = self
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

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
      presentedViewController = nil
    }

    // MARK: - Private Methods

    private func configurePresentation(
      for hostingController: UIViewController,
      presentedOverSheet: Bool
    ) {
      guard !presentedOverSheet else {
        hostingController.modalPresentationStyle = .overFullScreen
        return
      }

      hostingController.modalPresentationStyle = .pageSheet
      hostingController.sheetPresentationController?.detents = [.large()]
      hostingController.sheetPresentationController?.prefersGrabberVisible = true
      hostingController.sheetPresentationController?.prefersScrollingExpandsWhenScrolledToEdge = false
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
