@preconcurrency import Foundation
import SwiftUI
@_exported import TraceLensCore
import TraceLensCore
import TraceLensStorage
import TraceLensCapture
import TraceLensMetrics
import TraceLensUI

private actor TraceLensCoordinator {
    var store: SessionStore?; var bodies: TemporaryBodyStore?; var configuration = TraceLensConfiguration()
    func start(_ configuration: TraceLensConfiguration) async { if let bodies { await bodies.clear() }; TemporaryBodyStore.cleanupStaleDirectories(); self.configuration = configuration; let store = SessionStore(configuration: configuration); do { let bodies = try TemporaryBodyStore(limits: configuration.sessionLimits); self.store = store; self.bodies = bodies; await CaptureRuntime.shared.start(configuration: configuration, store: store, bodies: bodies); await MainActor.run { TraceLens.presentation = .init(store: store, configuration: configuration, visible: TraceLens.presentation.visible) } } catch { self.store = store; self.bodies = nil; await MainActor.run { TraceLens.presentation = .init(store: store, configuration: configuration, visible: TraceLens.presentation.visible) } } }
    func stop() async { await CaptureRuntime.shared.stop(); if let bodies { await bodies.clear() }; store = nil; bodies = nil; await MainActor.run { TraceLens.presentation = .init() } }
    func clear() async { if let store { await store.clear() }; if let bodies { await bodies.clear() } }
    func update(_ configuration: TraceLensConfiguration) async { self.configuration = configuration; let currentStore = store; await currentStore?.updateLimits(configuration.sessionLimits); await CaptureRuntime.shared.updateConfiguration(configuration); await MainActor.run { TraceLens.presentation = .init(store: currentStore, configuration: configuration, visible: TraceLens.presentation.visible) } }
    func export() async throws -> URL { guard let store else { throw TraceLensError.notStarted }; let snapshot = await store.snapshot(); let root = FileManager.default.temporaryDirectory.appending(path: "TraceLensSession-\(snapshot.session.id.uuidString).tracelens", directoryHint: .isDirectory); try? FileManager.default.removeItem(at: root); try FileManager.default.createDirectory(at: root.appending(path: "requests", directoryHint: .isDirectory), withIntermediateDirectories: true); try FileManager.default.createDirectory(at: root.appending(path: "responses", directoryHint: .isDirectory), withIntermediateDirectories: true); var exported = snapshot.transactions; if configuration.sensitiveDataPolicy == .redacted { for index in exported.indices { exported[index].request.headers = SensitiveData.headers(exported[index].request.headers, policy: .redacted); if var response = exported[index].response { response.headers = SensitiveData.headers(response.headers, policy: .redacted); exported[index].response = response } } }; let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601; try encoder.encode(exported).write(to: root.appending(path: "transactions.json")); let metrics = MetricsAggregator().aggregate(snapshot.transactions); let metricData = try JSONSerialization.data(withJSONObject: ["totalRequests": metrics.totalRequests, "errorRate": metrics.errorRate, "fullCaptureRatio": metrics.fullCaptureRatio], options: [.prettyPrinted, .sortedKeys]); try metricData.write(to: root.appending(path: "metrics.json")); let manifest = try JSONSerialization.data(withJSONObject: ["sessionID": snapshot.session.id.uuidString, "startedAt": ISO8601DateFormatter().string(from: snapshot.session.startedAt), "format": "TraceLens Session"], options: [.prettyPrinted, .sortedKeys]); try manifest.write(to: root.appending(path: "manifest.json")); return root }
}
public enum TraceLensError: Error, LocalizedError { case notStarted; public var errorDescription: String? { "O TraceLens ainda não foi iniciado." } }
@MainActor private struct Presentation { var store: SessionStore? = nil; var configuration = TraceLensConfiguration(); var visible = false }
public enum TraceLens {
    private static let coordinator = TraceLensCoordinator()
    @MainActor fileprivate static var presentation = Presentation()
    public static func start(configuration: TraceLensConfiguration = .init()) { Task { await coordinator.start(configuration) } }
    public static func stop() { Task { await coordinator.stop() } }
    public static func updateConfiguration(_ configuration: TraceLensConfiguration) { Task { await coordinator.update(configuration) } }
    @MainActor public static func show() { presentation.visible = true }
    @MainActor public static func hide() { presentation.visible = false }
    public static func clearSession() async { await coordinator.clear() }
    public static func exportSession() async throws -> URL { try await coordinator.export() }
    public static func instrument(_ configuration: URLSessionConfiguration) -> URLSessionConfiguration { URLSessionInstrumentation.instrument(configuration) }
}
public struct TraceLensView: View {
    private let onClose: (() -> Void)?

    /// Creates the TraceLens dashboard.
    ///
    /// - Parameter onClose: Optional action shown as a close button in the
    ///   dashboard navigation bar. Supply this when presenting the view modally.
    public init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }

    public var body: some View {
        TraceLensDashboard(
            store: TraceLens.presentation.store,
            configuration: TraceLens.presentation.configuration,
            onClose: onClose,
            onConfigurationChange: TraceLens.updateConfiguration,
            onClear: TraceLens.clearSession,
            onExport: TraceLens.exportSession
        )
    }
}
public enum CurlExporter {
    public static func command(for transaction: NetworkTransaction, policy: SensitiveDataPolicy) -> String? { guard transaction.captureLevel == .full else { return nil }; var parts = ["curl", "-X", transaction.request.method.rawValue, shellQuote(transaction.request.url.absoluteString)]; for (key, value) in SensitiveData.headers(transaction.request.headers, policy: policy).sorted(by: { $0.key < $1.key }) { parts += ["-H", shellQuote("\(key): \(value)")] }; if policy == .visible, case .inline = transaction.request.body.storage, let data = transaction.request.body.data, let body = String(data: data, encoding: .utf8) { parts += ["--data-raw", shellQuote(body)] }; return parts.joined(separator: " ") }
    private static func shellQuote(_ value: String) -> String { "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'" }
}
