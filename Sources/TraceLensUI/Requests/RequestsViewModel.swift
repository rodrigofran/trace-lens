import SwiftUI
import TraceLensCore
import TraceLensMetrics
import TraceLensStorage

#if os(iOS) || os(tvOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

@MainActor
public final class TraceLensViewModel: ObservableObject {
  // MARK: - Published state

  @Published public private(set) var snapshot: SessionSnapshot?
  @Published public var search = ""
  @Published public var method: HTTPMethod?
  @Published public var capture: CaptureLevel?
  @Published public var statusFilter: StatusFilter = .all
  @Published public var sortOrder: RequestSortOrder = .newestFirst
  @Published public var settings: TraceLensConfiguration

  // MARK: - Private state

  private var task: Task<Void, Never>?

  // MARK: - Initialization

  public init(store: SessionStore?, configuration: TraceLensConfiguration = .init()) {
    settings = configuration

    guard let store else {
      return
    }

    task = Task { [weak self] in
      for await value in await store.updates() {
        if Task.isCancelled {
          break
        }

        self?.snapshot = value
      }
    }
  }

  deinit {
    task?.cancel()
  }

  // MARK: - Derived state

  public var transactions: [NetworkTransaction] {
    let filtered = (snapshot?.transactions ?? []).filter { tx in
      let text = [
        tx.request.parsed.host,
        tx.request.parsed.displayService,
        tx.request.parsed.technicalService,
        tx.request.parsed.endpoint,
        tx.request.parsed.fullURL,
        tx.request.method.rawValue,
        tx.response.map { String($0.statusCode) },
      ]
      .compactMap { $0 }
      .joined(separator: " ")
      .lowercased()

      return (search.isEmpty || text.contains(search.lowercased()))
        && (method == nil || method == tx.request.method)
        && (capture == nil || capture == tx.captureLevel)
        && statusFilter.matches(tx)
    }

    return filtered.sorted { first, second in
      switch sortOrder {
      case .newestFirst:
        first.startedAt > second.startedAt

      case .oldestFirst:
        first.startedAt < second.startedAt
      }
    }
  }

  public var totalTransactions: Int {
    snapshot?.transactions.count ?? 0
  }
}

public enum RequestSortOrder: String, CaseIterable, Identifiable {
  case newestFirst
  case oldestFirst

  public var id: Self {
    self
  }

  var title: String {
    switch self {
    case .newestFirst:
      "Mais recentes"
    case .oldestFirst:
      "Mais antigas"
    }
  }

  var icon: String {
    switch self {
    case .newestFirst:
      "arrow.down"
    case .oldestFirst:
      "arrow.up"
    }
  }
}

public enum StatusFilter: String, CaseIterable, Identifiable {
  case all
  case errors

  public var id: String {
    rawValue
  }

  func matches(_ transaction: NetworkTransaction) -> Bool {
    switch self {
    case .all:
      return true

    case .errors:
      if transaction.error != nil {
        return true
      }

      guard let statusCode = transaction.response?.statusCode else {
        return false
      }

      return statusCode >= 400
    }
  }
}
