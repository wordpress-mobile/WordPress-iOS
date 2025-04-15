import XCTest
@testable import WordPress

class PluginDirectoryEntryStateTests: XCTestCase {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "YYYY-MM-dd h:mma z"
        return formatter
    }()

    static let jetpackEntry: PluginDirectoryEntry = {
        let json = Bundle(for: PluginDirectoryEntryStateTests.self).url(forResource: "plugin-directory-jetpack", withExtension: "json")!
        let data = try! Data(contentsOf: json)

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(PluginDirectoryEntryStateTests.dateFormatter)

        return try! jsonDecoder.decode(PluginDirectoryEntry.self, from: data)
    }()

    func testMoreSpecificDirectoryEntryStateWins() {
        let complete = PluginDirectoryEntryState.present(PluginDirectoryEntryStateTests.jetpackEntry)
        let partial = PluginDirectoryEntryState.partial(PluginDirectoryEntryStateTests.jetpackEntry)

        let moreSpecific = PluginDirectoryEntryState.moreSpecific(complete, partial)

        if case .present = moreSpecific {
            XCTAssertTrue(true)
        } else {
            XCTAssert(false, "Should have matched .present!")
        }
    }

    func testMoreSpecificOrderDoesntMatter() {
        let complete = PluginDirectoryEntryState.present(PluginDirectoryEntryStateTests.jetpackEntry)
        let partial = PluginDirectoryEntryState.partial(PluginDirectoryEntryStateTests.jetpackEntry)

        let moreSpecific = PluginDirectoryEntryState.moreSpecific(partial, complete)

        if case .present = moreSpecific {
            XCTAssertTrue(true)
        } else {
            XCTAssert(false, "Should have matched .present!")
        }
    }

    func testPresentMoreSpecificThanMissing() {
        let complete = PluginDirectoryEntryState.present(PluginDirectoryEntryStateTests.jetpackEntry)
        let missing = PluginDirectoryEntryState.missing(Date())

        let moreSpecific = PluginDirectoryEntryState.moreSpecific(missing, complete)

        if case .present = moreSpecific {
            XCTAssertTrue(true)
        } else {
            XCTAssert(false, "Should have matched .present!")
        }
    }

    func testPresentMoreSpecificThanUnknown() {
        let complete = PluginDirectoryEntryState.present(PluginDirectoryEntryStateTests.jetpackEntry)
        let unknown = PluginDirectoryEntryState.unknown

        let moreSpecific = PluginDirectoryEntryState.moreSpecific(unknown, complete)

        if case .present = moreSpecific {
            XCTAssertTrue(true)
        } else {
            XCTAssert(false, "Should have matched .present!")
        }
    }

    func testPartialMoreSpecifingThanMissing() {
        let partial = PluginDirectoryEntryState.partial(PluginDirectoryEntryStateTests.jetpackEntry)
        let missing = PluginDirectoryEntryState.missing(Date())

        let moreSpecific = PluginDirectoryEntryState.moreSpecific(missing, partial)

        if case .partial = moreSpecific {
            XCTAssertTrue(true)
        } else {
            XCTAssert(false, "Should have matched .partial!")
        }
    }

    func testPartialMoreSpecificThanUnknown() {
        let partial = PluginDirectoryEntryState.partial(PluginDirectoryEntryStateTests.jetpackEntry)
        let unknown = PluginDirectoryEntryState.unknown

        let moreSpecific = PluginDirectoryEntryState.moreSpecific(unknown, partial)

        if case .partial = moreSpecific {
            XCTAssertTrue(true)
        } else {
            XCTAssert(false, "Should have matched .partial!")
        }
    }

    func testMissingMoreSpecificThanUnknown() {
        let missing = PluginDirectoryEntryState.missing(Date())
        let unknown = PluginDirectoryEntryState.unknown

        let moreSpecific = PluginDirectoryEntryState.moreSpecific(missing, unknown)

        if case .missing = moreSpecific {
            XCTAssertTrue(true)
        } else {
            XCTAssert(false, "Should have matched .missing!")
        }
    }
}
