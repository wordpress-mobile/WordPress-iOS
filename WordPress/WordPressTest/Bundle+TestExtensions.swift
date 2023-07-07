import Foundation
import XCTest

extension Bundle {
    static var test: Bundle { Bundle(for: TestBundleToken.self) }

    func json(named name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle(for: TestBundleToken.self)
            .url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}

private final class TestBundleToken {}
