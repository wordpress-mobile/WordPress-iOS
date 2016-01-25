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

    // MARK: - request

    func testRequestSuccessful() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 0.01)
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
        service.testScheduler = scheduler

        let res = scheduler.start {
            service.request
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(res.events, [
            next(200, .Refreshing),
            next(210, .Idle),
            completed(210)
            ])
    }

    func testRequestOneNetworkErrorShouldRetry() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 0.01)
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
        service.testScheduler = scheduler

        let res = scheduler.start {
            service.request
        }

        XCTAssertEqual(requestCount, 2)
        XCTAssertEqual(res.events, [
            next(200, .Refreshing),
            next(220, .Idle),
            completed(220)
            ])
    }

    func testRequestFourNetworkErrorsShouldFail() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 0.01)
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
        service.testScheduler = scheduler

        let res = scheduler.start {
            service.request
        }

        XCTAssertEqual(requestCount, 3)
        XCTAssertEqual(res.events, [
            next(200, .Refreshing),
            error(230, connectionLost)
            ])
    }

    func testRequestUnrecoverableErrorsShouldFailImmediately() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 0.01)
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
        service.testScheduler = scheduler

        let res = scheduler.start {
            service.request
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(res.events, [
            next(200, .Refreshing),
            error(210, unexpected)
            ])
    }

    func testRequestEmitsStalledValue() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 0.01)
        let mockRemote = MockAccountSettingsRemote()
        var requestCount = 0
        mockRemote.settings = Observable<AccountSettings>.create { observer in
            requestCount += 1
            return scheduler.scheduleRelativeVirtual(requestCount, dueTime: 500, action: { _ in
                observer.on(.Next(TestData.sampleSettings))
                observer.on(.Completed)
                return NopDisposable.instance
            })
        }

        let service = AccountSettingsService(userID: 123, remote: mockRemote)
        service.testScheduler = scheduler

        let res = scheduler.start {
            service.request
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(res.events, [
            next(200, .Refreshing),
            next(600, .Stalled),
            next(700, .Idle),
            completed(700)
            ])
    }

    // MARK: - refresh

    func testRefreshRepeatsSuccessfulRequest() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 0.1)
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
        service.testScheduler = scheduler

        let res = scheduler.start {
            service.refresh
        }

        XCTAssertEqual(requestCount, 2)
        XCTAssertEqual(res.events, [
            next(200, .Refreshing),
            next(210, .Idle),
            next(800, .Refreshing),
            next(810, .Idle)
            ])
    }

    func testRefreshDoesntRepeatFailedRequest() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 0.1)
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
        service.testScheduler = scheduler

        let res = scheduler.start {
            service.refresh
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(res.events, [
            next(200, .Refreshing),
            error(210, unexpected)
            ])
    }

    func testRefreshDoesntRequestIfUnreachable() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 0.1)
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
        service.testScheduler = scheduler
        service.testReachability = Observable.create { observer in
            return scheduler.scheduleAbsoluteVirtual((), time: 200, action: { _ in
                observer.on(.Next(false))
                return NopDisposable.instance
            })
        }

        let res = scheduler.start {
            service.refresh
        }

        XCTAssertEqual(requestCount, 0)
        XCTAssertEqual(res.events, [
            next(200, .Offline),
            ])

    }

    func testRefreshRetriesWhenReachable() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 0.1)
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
        service.testScheduler = scheduler
        service.testReachability = Observable.create { observer in
            scheduler.scheduleAbsoluteVirtual((), time: 200, action: { _ in
                observer.on(.Next(false))
                return NopDisposable.instance
            })
            scheduler.scheduleAbsoluteVirtual((), time: 500, action: { _ in
                observer.on(.Next(true))
                return NopDisposable.instance
            })
            scheduler.scheduleAbsoluteVirtual((), time: 800, action: { _ in
                observer.on(.Next(false))
                return NopDisposable.instance
            })
            return NopDisposable.instance
        }

        let res = scheduler.start {
            service.refresh
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(res.events, [
            next(200, .Offline),
            next(500, .Refreshing),
            next(510, .Idle),
            next(800, .Offline)
            ])
    }

    func testRefreshDoesntRepeatFailedRequestAfterReachable() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 0.1)
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
        service.testScheduler = scheduler
        service.testReachability = Observable.create { observer in
            scheduler.scheduleAbsoluteVirtual((), time: 200, action: { _ in
                observer.on(.Next(false))
                return NopDisposable.instance
            })
            scheduler.scheduleAbsoluteVirtual((), time: 500, action: { _ in
                observer.on(.Next(true))
                return NopDisposable.instance
            })
            scheduler.scheduleAbsoluteVirtual((), time: 800, action: { _ in
                observer.on(.Next(false))
                return NopDisposable.instance
            })
            return NopDisposable.instance
        }

        let res = scheduler.start {
            service.refresh
        }

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(res.events, [
            next(200, .Offline),
            next(500, .Refreshing),
            error(510, unexpected)
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
