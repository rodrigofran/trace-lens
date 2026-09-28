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

  func testHostRuleExtractsPathPrefixFromBaseURLWithoutScheme() throws {
    let rule = ObservationRule.host("api.example.test/v1/", capture: .full)
    let matchingURL = try XCTUnwrap(URL(string: "https://api.example.test/v1/payments"))
    let otherPathURL = try XCTUnwrap(URL(string: "https://api.example.test/v2/payments"))

    XCTAssertEqual(rule.matcher.host, "api.example.test")
    XCTAssertEqual(rule.matcher.pathPrefix, "/v1")
    XCTAssertTrue(rule.matcher.matches(matchingURL, method: .get))
    XCTAssertFalse(rule.matcher.matches(otherPathURL, method: .get))
  }

  func testHostRuleExtractsPathPrefixFromCompleteURL() throws {
    let rule = ObservationRule.host(
      "https://api.example.test/api/v2/sicredi?ignored=true",
      capture: .full
    )
    let matchingURL = try XCTUnwrap(
      URL(string: "https://api.example.test/api/v2/sicredi/accounts")
    )

    XCTAssertEqual(rule.matcher.host, "api.example.test")
    XCTAssertEqual(rule.matcher.pathPrefix, "/api/v2/sicredi")
    XCTAssertTrue(rule.matcher.matches(matchingURL, method: .get))
  }
}
