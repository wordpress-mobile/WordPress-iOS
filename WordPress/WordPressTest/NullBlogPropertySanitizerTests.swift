import XCTest
import Nimble

@testable import WordPress

class NullBlogPropertySanitizerTests: XCTestCase {
    private var keyValueStore: StubKeyValueDatabase!
    private var nullBlogPropertySanitizer: NullBlogPropertySanitizer!

    private var context: NSManagedObjectContext!

    private var currentBuildVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    override func setUp() {
        super.setUp()
        context = TestContextManager().mainContext
        keyValueStore = StubKeyValueDatabase()
        nullBlogPropertySanitizer = NullBlogPropertySanitizer(store: keyValueStore, context: context)
    }

    override func tearDown() {
        super.tearDown()
        nullBlogPropertySanitizer = nil
        keyValueStore = nil
        context = nil
        ContextManager.overrideSharedInstance(nil)
    }

    func testSetsTheSanitizedVersionEqualToCurrentBuildVersion() {
        keyValueStore.lastSanitizationVersionNumber = "10.0"

        nullBlogPropertySanitizer.sanitize()

        expect(self.keyValueStore.lastSanitizationVersionNumber).to(equal(currentBuildVersion))
    }

    func testDoesntChangeVersionWhenSanitizationIsNotNeeded() {
        keyValueStore.lastSanitizationVersionNumber = currentBuildVersion

        nullBlogPropertySanitizer.sanitize()

        expect(self.keyValueStore.setCalledWith).to(beNil())
    }
}

private class StubKeyValueDatabase: EphemeralKeyValueDatabase {
    private(set) var setCalledWith: Any?

    var lastSanitizationVersionNumber: String? {
        get {
            object(forKey: NullBlogPropertySanitizer.lastSanitizationVersionNumber) as? String
        }
        set {
            set(newValue, forKey: NullBlogPropertySanitizer.lastSanitizationVersionNumber)
        }
    }

    override func set(_ value: Any?, forKey aKey: String) {
        super.set(value, forKey: aKey)
        setCalledWith = value
    }
}
