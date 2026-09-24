import Foundation
import TraceLensCapture
import TraceLensCore
import TraceLensStorage

actor TraceLensCoordinator {
  // MARK: - State

  private var store: SessionStore?
  private var bodies: TemporaryBodyStore?
  private var configuration = TraceLensConfiguration()

  // MARK: - Lifecycle

  func start(_ configuration: TraceLensConfiguration) async {
    if let bodies {
      await bodies.clear()
    }

    TemporaryBodyStore.cleanupStaleDirectories()
    self.configuration = configuration

    let store = SessionStore(configuration: configuration)

    do {
      let bodies = try TemporaryBodyStore(limits: configuration.sessionLimits)

      self.store = store
      self.bodies = bodies

      await CaptureRuntime.shared.start(
        configuration: configuration,
        store: store,
        bodies: bodies
      )

      await updatePresentation(store: store, configuration: configuration)
    } catch {
      self.store = store
      self.bodies = nil

      await updatePresentation(store: store, configuration: configuration)
    }
  }

  func stop() async {
    await CaptureRuntime.shared.stop()

    if let bodies {
      await bodies.clear()
    }

    store = nil
    bodies = nil

    await MainActor.run {
      TraceLens.presentation = .init()
    }
  }

  // MARK: - Session Management

  func clear() async {
    if let store {
      await store.clear()
    }

    if let bodies {
      await bodies.clear()
    }
  }

  func update(_ configuration: TraceLensConfiguration) async {
    self.configuration = configuration

    await store?.updateLimits(configuration.sessionLimits)
    await CaptureRuntime.shared.updateConfiguration(configuration)
    await updatePresentation(store: store, configuration: configuration)
  }

  // MARK: - Export

  func export() async throws -> URL {
    guard let store else {
      throw TraceLensError.notStarted
    }

    let snapshot = await store.snapshot()

    return try SessionExporter.export(
      snapshot: snapshot,
      configuration: configuration
    )
  }

  // MARK: - Presentation

  private func updatePresentation(
    store: SessionStore?,
    configuration: TraceLensConfiguration
  ) async {
    await MainActor.run {
      TraceLens.presentation = .init(
        store: store,
        configuration: configuration,
        visible: TraceLens.presentation.visible
      )
    }
  }
}
