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

    func testBoolReturnsStandardValueWhenTrueAndSuiteNotSet() {
        guard let sut = sut else {
            XCTFail("No `sut` found")
            return
        }

        let key = #function

        UserDefaults.standard.set(true, forKey: key)
        XCTAssert(sut.bool(forKey: key))
    }

    func testBoolReturnsFalseWhenStandardValueIsTrueAndSuiteSetToFalse() {
        guard let sut = sut else {
            XCTFail("No `sut` found")
            return
        }

        let key = #function

        UserDefaults.standard.set(true, forKey: key)
        sut.set(false, forKey: key)
        XCTAssertFalse(sut.bool(forKey: key))
    }

    func testBoolReturnsTrueWhenStandardValueIsFalseAndSuiteSetToTrue() {
        guard let sut = sut else {
            XCTFail("No `sut` found")
            return
        }

        let key = #function

        UserDefaults.standard.set(false, forKey: key)
        sut.set(true, forKey: key)
        XCTAssert(sut.bool(forKey: key))
    }

    func testSetIntUpdatesDefaults() {
        let key = #function
        sut?.set(1987, forKey: key)

        guard let userDefaults = UserDefaults(suiteName: Self.mockSuiteName) else {
            XCTFail("Initialization with \(Self.mockSuiteName) failed.")
            return
        }

        XCTAssertEqual(userDefaults.integer(forKey: key), 1987)
        userDefaults.removeObject(forKey: key)
        sut?.removeObject(forKey: key)
    }

    func testSetIntInvalidatesStandardValue() {
        guard let sut = sut else {
            XCTFail("No `sut` found")
            return
        }

        let key = #function
        let testValue: Int = 991
        UserDefaults.standard.set(testValue, forKey: key)
        sut.set(testValue, forKey: key)

        XCTAssertEqual(sut.integer(forKey: key), testValue)
        XCTAssertEqual(UserDefaults.standard.double(forKey: key), 0)
        sut.removeObject(forKey: key)
    }

    func testSetFloatUpdatesDefaults() {
        let key = #function
        let testValue: Float = 7.2
        sut?.set(testValue, forKey: key)

        guard let userDefaults = UserDefaults(suiteName: Self.mockSuiteName) else {
            XCTFail("Initialization with \(Self.mockSuiteName) failed.")
            return
        }

        XCTAssertEqual(userDefaults.float(forKey: key), testValue)
        sut?.removeObject(forKey: key)
    }

    func testSetFloatInvalidatesStandardValue() {
        guard let sut = sut else {
            XCTFail("No `sut` found")
            return
        }

        let key = #function
        let testValue: Float = 15.23
        UserDefaults.standard.set(testValue, forKey: key)
        sut.set(testValue, forKey: key)

        XCTAssertEqual(sut.float(forKey: key), testValue)
        XCTAssertEqual(UserDefaults.standard.double(forKey: key), 0)
        sut.removeObject(forKey: key)
    }

    func testSetDoubleUpdatesDefaults() {
        let key = #function
        let testValue: Double = 18.82732
        sut?.set(testValue, forKey: key)

        guard let userDefaults = UserDefaults(suiteName: Self.mockSuiteName) else {
            XCTFail("Initialization with \(Self.mockSuiteName) failed.")
            return
        }

        XCTAssertEqual(userDefaults.double(forKey: key), testValue)
        sut?.removeObject(forKey: key)
    }

    func testSetDoubleInvalidatesStandardValue() {
        guard let sut = sut else {
            XCTFail("No `sut` found")
            return
        }

        let key = #function
        let testValue: Double = 18.82732
        UserDefaults.standard.set(testValue, forKey: key)
        sut.set(testValue, forKey: key)

        XCTAssertEqual(sut.double(forKey: key), testValue)
        XCTAssertEqual(UserDefaults.standard.double(forKey: key), 0)
        sut.removeObject(forKey: key)
    }

    func testSetBoolUpdatesDefaults() {
        let key = #function
        sut?.set(true, forKey: key)

        guard let userDefaults = UserDefaults(suiteName: Self.mockSuiteName) else {
            XCTFail("Initialization with \(Self.mockSuiteName) failed.")
            return
        }

        XCTAssert(userDefaults.bool(forKey: key))
        sut?.removeObject(forKey: key)
    }

    func testSetBoolInvalidatesStandardValue() {
        guard let sut = sut else {
            XCTFail("No `sut` found")
            return
        }

        let key = #function
        UserDefaults.standard.set(true, forKey: key)

        sut.set(true, forKey: key)

        XCTAssert(sut.bool(forKey: key))
        sut.removeObject(forKey: key)
    }

    func testSetURLUpdatesDefaults() {
        let key = #function
        let url = URL(string: "https://wordpress.com")!
        sut?.set(url, forKey: key)

        guard let userDefaults = UserDefaults(suiteName: Self.mockSuiteName) else {
            XCTFail("Initialization with \(Self.mockSuiteName) failed.")
            return
        }

        XCTAssertEqual(userDefaults.url(forKey: key), url)
        sut?.removeObject(forKey: key)
    }
}
