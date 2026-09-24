import XCTest

@testable import TraceLensCore

final class SensitiveDataTests: XCTestCase {
  func testRedactsKnownSensitiveHeaders() {
    XCTAssertEqual(
      SensitiveData.value("secret", key: "Authorization", policy: .redacted),
      "••••••••"
    )
    XCTAssertEqual(
      SensitiveData.value("ok", key: "Accept", policy: .redacted),
      "ok"
    )
  }
}
