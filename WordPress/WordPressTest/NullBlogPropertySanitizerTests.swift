import XCTest
import Nimble

@testable import WordPress

class NullBlogPropertySanitizerTests: CoreDataTestCase {
    private var keyValueDatabase: StubKeyValueDatabase!
    private var nullBlogPropertySanitizer: NullBlogPropertySanitizer!

    private var currentBuildVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    override func setUp() {
        super.setUp()
        keyValueDatabase = StubKeyValueDatabase()
        nullBlogPropertySanitizer = NullBlogPropertySanitizer(store: keyValueDatabase, context: mainContext)
    }

    override func tearDown() {
        super.tearDown()
        nullBlogPropertySanitizer = nil
        keyValueDatabase = nil
    }

    func testSetsTheSanitizedVersionEqualToCurrentBuildVersion() {
        keyValueDatabase[NullBlogPropertySanitizer.lastSanitizationVersionNumber] = "10.0"

        nullBlogPropertySanitizer.sanitize()

        expect(self.keyValueDatabase[NullBlogPropertySanitizer.lastSanitizationVersionNumber]).to(equal(currentBuildVersion))
    }

    func testDoesntChangeVersionWhenSanitizationIsNotNeeded() {
        // Given
        keyValueDatabase[NullBlogPropertySanitizer.lastSanitizationVersionNumber] = currentBuildVersion

        // When
        nullBlogPropertySanitizer.sanitize()

        // Then
        // The first invocation is in the _Given_ paragraph.
        expect(self.keyValueDatabase.setValueForKeyInvocationCount).to(equal(1))
    }
}

private class StubKeyValueDatabase: EphemeralKeyValueDatabase {
    private(set) var setValueForKeyInvocationCount = 0

    override func set(_ value: Any?, forKey aKey: String) {
        super.set(value, forKey: aKey)
        setValueForKeyInvocationCount += 1
    }
}
