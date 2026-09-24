import TraceLensCore
import TraceLensStorage

@MainActor
struct TraceLensPresentation {
  // MARK: - Properties

  var store: SessionStore?
  var configuration = TraceLensConfiguration()
  var visible = false
}
