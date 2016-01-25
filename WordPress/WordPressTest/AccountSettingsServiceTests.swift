import XCTest
import RxSwift
import RxTests
@testable import WordPress

class AccountSettingsServiceTests: XCTestCase {
    struct TestData {
        static let sampleSettings = AccountSettings(
            firstName: "Jorge",
            lastName: "Bernal",
            displayName: "Jorge Bernal",
            aboutMe: "A description about me",
            username: "koketest",
            email: "koke@example.com",
            primarySiteID: 16764956,
            webAddress: "http://koke.me",
            language: "es"
        )
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRemoteSettingsSuccessful() {
        let scheduler = TestScheduler(initialClock: 0)
        let mockRemote = MockAccountSettingsRemote()
        var requestCount = 0
        mockRemote.settings = Observable<AccountSettings>.create { observer in
            requestCount += 1
            return scheduler.scheduleRelativeVirtual(requestCount, dueTime: 10, action: { _ in
                observer.on(.Next(TestData.sampleSettings))
                observer.on(.Completed)
                return NopDisposable.instance
            })
        }

        let service = AccountSettingsService(userID: 123, remote: mockRemote)

        let res = scheduler.start {
            service.remoteSettings
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(res.events, [
            next(200, .Refreshing),
            next(210, .Idle),
            completed(210)
            ])
    }

    func testRemoteSettingsOneNetworkErrorShouldRetry() {
        let scheduler = TestScheduler(initialClock: 0)
        let mockRemote = MockAccountSettingsRemote()
        var requestCount = 0
        mockRemote.settings = Observable<AccountSettings>.create { observer in
            requestCount += 1
            return scheduler.scheduleRelativeVirtual(requestCount, dueTime: 10, action: { _ in
                if requestCount == 1 {
                    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)
                    observer.on(.Error(error))
                } else {
                    observer.on(.Next(TestData.sampleSettings))
                    observer.on(.Completed)
                }
                return NopDisposable.instance
            })
        }

        let service = AccountSettingsService(userID: 123, remote: mockRemote)

        let res = scheduler.start {
            service.remoteSettings
        }

        XCTAssertEqual(requestCount, 2)
        XCTAssertEqual(res.events, [
            next(200, .Refreshing),
            next(220, .Idle),
            completed(220)
            ])
    }

    func testRemoteSettingsFourNetworkErrorsShouldFail() {
        let scheduler = TestScheduler(initialClock: 0)
        let mockRemote = MockAccountSettingsRemote()
        var requestCount = 0
        let connectionLost = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        mockRemote.settings = Observable<AccountSettings>.create { observer in
            requestCount += 1
            return scheduler.scheduleRelativeVirtual(requestCount, dueTime: 10, action: { _ in
                observer.on(.Error(connectionLost))
                return NopDisposable.instance
            })
        }

        let service = AccountSettingsService(userID: 123, remote: mockRemote)

        let res = scheduler.start {
            service.remoteSettings
        }

        XCTAssertEqual(requestCount, 3)
        XCTAssertEqual(res.events, [
            next(200, .Refreshing),
            next(230, .Failed),
            completed(230)
            ])
    }

    func testRemoteSettingsUnrecoverableErrorsShouldFailImmediately() {
        let scheduler = TestScheduler(initialClock: 0)
        let mockRemote = MockAccountSettingsRemote()
        var requestCount = 0
        let unexpected = NSError(domain: "Unexpected", code: -999, userInfo: nil)
        mockRemote.settings = Observable<AccountSettings>.create { observer in
            requestCount += 1
            return scheduler.scheduleRelativeVirtual(requestCount, dueTime: 10, action: { _ in
                observer.on(.Error(unexpected))
                return NopDisposable.instance
            })
        }

        let service = AccountSettingsService(userID: 123, remote: mockRemote)

        let res = scheduler.start {
            service.remoteSettings
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(res.events, [
            next(200, .Refreshing),
            next(210, .Failed),
            completed(210)
            ])
    }

}

class MockAccountSettingsRemote: AccountSettingsRemoteInterface {
    var settings: Observable<AccountSettings> = Observable<AccountSettings>.never()

    var mockUpdateSetting: (AccountSettingsChange, () -> Void, ErrorType -> Void) -> Void = { _, _, _ in }

    func updateSetting(change: AccountSettingsChange, success: () -> Void, failure: ErrorType -> Void) {
        mockUpdateSetting(change, success, failure)
    }
}
