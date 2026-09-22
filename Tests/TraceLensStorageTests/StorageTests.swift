import XCTest
@testable import TraceLensStorage
@testable import TraceLensCore

final class StorageTests: XCTestCase {
    func testTemporaryStorageAndClear() async throws { let store = try TemporaryBodyStore(limits: .init(maxTransactions: 10, maxBodyBytes: 100_000, maxTemporaryStorageBytes: 200_000)); let body = await store.store(Data("hello".utf8), kind: "request"); let restored = await store.data(for: body); XCTAssertEqual(restored, Data("hello".utf8)); await store.clear(); let bytes = await store.byteCount(); XCTAssertEqual(bytes, 0) }
    func testNextRuleConsumption() async throws { let config = TraceLensConfiguration(); let store = SessionStore(configuration: config); await store.addNextRule(.host("api.example.test", capture: .full, origin: .nextRequest)); let url = try XCTUnwrap(URL(string: "https://api.example.test/a")); let first = await store.resolve(url: url, method: .get, defaultCapture: .metadata); let second = await store.resolve(url: url, method: .get, defaultCapture: .metadata); XCTAssertEqual(first.0, .full); XCTAssertEqual(second.0, .metadata) }
}
