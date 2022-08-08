import XCTest
@testable import WordPress

final class UserPersistentStoreTests: XCTestCase {
    private static let mockSuiteName = "user.persistent.store.tests"
    private let sut = UserPersistentStore(defaultsSuiteName: mockSuiteName)

    // From the `UserDefaults(suiteName:)` docs:
    // "The globalDomain is also an invalid suite name, because it isn't writeable by apps."
    // Therefore it should return nil.
    func testInitFailsWhenGlobalDomainIsUsed() {
        XCTAssertNil(UserPersistentStore(defaultsSuiteName: UserDefaults.globalDomain))
    }

    func testSetIntUpdatesDefaults() {
        let keyName = #function
        sut?.set(1987, forKey: keyName)

        guard let userDefaults = UserDefaults(suiteName: Self.mockSuiteName) else {
            XCTFail("Initialization with \(Self.mockSuiteName) failed.")
            return
        }

        XCTAssertEqual(userDefaults.integer(forKey: keyName), 1987)
        userDefaults.removeObject(forKey: keyName)
    }

    func testSetFloatUpdatesDefaults() {
        let keyName = #function
        let testValue: Float = 7.2
        sut?.set(testValue, forKey: keyName)

        guard let userDefaults = UserDefaults(suiteName: Self.mockSuiteName) else {
            XCTFail("Initialization with \(Self.mockSuiteName) failed.")
            return
        }

        XCTAssertEqual(userDefaults.float(forKey: keyName), testValue)
        userDefaults.removeObject(forKey: keyName)
    }

    func testSetDoubleUpdatesDefaults() {
        let keyName = #function
        let testValue: Double = 18.82732
        sut?.set(testValue, forKey: keyName)

        guard let userDefaults = UserDefaults(suiteName: Self.mockSuiteName) else {
            XCTFail("Initialization with \(Self.mockSuiteName) failed.")
            return
        }

        XCTAssertEqual(userDefaults.double(forKey: keyName), testValue)
        userDefaults.removeObject(forKey: keyName)
    }

    func testSetBoolUpdatesDefaults() {
        let keyName = #function
        sut?.set(true, forKey: keyName)

        guard let userDefaults = UserDefaults(suiteName: Self.mockSuiteName) else {
            XCTFail("Initialization with \(Self.mockSuiteName) failed.")
            return
        }

        XCTAssert(userDefaults.bool(forKey: keyName))
        userDefaults.removeObject(forKey: keyName)
    }

    func testSetURLUpdatesDefaults() {
        let keyName = #function
        let url = URL(string: "https://wordpress.com")!
        sut?.set(url, forKey: keyName)

        guard let userDefaults = UserDefaults(suiteName: Self.mockSuiteName) else {
            XCTFail("Initialization with \(Self.mockSuiteName) failed.")
            return
        }

        XCTAssertEqual(userDefaults.url(forKey: keyName), url)
        userDefaults.removeObject(forKey: keyName)
    }
}
