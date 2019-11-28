import XCTest
import Nimble

@testable import WordPress

class NullBlogPropertySanitizerTests: XCTestCase {
    private var keyValueStore: KeyValueStore!
    private var nullBlogPropertySanitizer: NullBlogPropertySanitizer!

    private var context: NSManagedObjectContext!

    var currentBuildVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    override func setUp() {
        super.setUp()
        context = TestContextManager().mainContext
        keyValueStore = KeyValueStore()
        nullBlogPropertySanitizer = NullBlogPropertySanitizer(store: keyValueStore, context: context)
    }

    override func tearDown() {
        super.tearDown()
        nullBlogPropertySanitizer = nil
        context = nil
        ContextManager.overrideSharedInstance(nil)
    }

    func testSetsTheSanitizedVersionEqualToCurrentBuildVersion() {
        keyValueStore.lastSanitizationVersionNumber = "10.0"

        nullBlogPropertySanitizer.sanitize()

        expect(self.keyValueStore.setCalledWith?.description).to(equal(currentBuildVersion))
    }

    func testDoesntChangeVersionWhenSanitizationIsNotNeeded() {
        keyValueStore.lastSanitizationVersionNumber = currentBuildVersion

        nullBlogPropertySanitizer.sanitize()

        expect(self.keyValueStore.setCalledWith).to(beNil())
    }

}

private class KeyValueStore: UserDefaults {
    var lastSanitizationVersionNumber: String?
    var setCalledWith: String?

    override func string(forKey defaultName: String) -> String? {
        return lastSanitizationVersionNumber!
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        setCalledWith = value as? String
    }
}
