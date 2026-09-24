import XCTest

@testable import TraceLensCore

final class RequestMatcherTests: XCTestCase {
  func testMatcherAndSpecificity() throws {
    let url = try XCTUnwrap(URL(string: "https://api.example.test/payments/create"))

    XCTAssertTrue(
      RequestMatcher(
        host: "api.example.test",
        pathPrefix: "/payments",
        methods: [.post]
      )
      .matches(url, method: .post)
    )
    XCTAssertFalse(
      RequestMatcher(host: "api.example.test", methods: [.get]).matches(url, method: .post)
    )
    XCTAssertGreaterThan(
      RequestMatcher(host: "api.example.test", pathPrefix: "/payments").specificity,
      RequestMatcher(host: "api.example.test").specificity
    )
  }
}
