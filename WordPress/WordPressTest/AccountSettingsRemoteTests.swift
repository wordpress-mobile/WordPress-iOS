import XCTest
import Nimble
import OHHTTPStubs
import RxSwift
@testable import WordPress

class AccountSettingsRemoteTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // It should be already empty if we did memory management right
        // But let's be safe
        AccountSettingsRemote.remotes.removeAllObjects()
        OHHTTPStubs.removeAllStubs()

        super.tearDown()
    }

    func testRemoteWithApiDoesntDuplicateRemotes() {
        let api = WordPressComApi(OAuthToken: "authtoken1")
        let remote1 = AccountSettingsRemote.remoteWithApi(api)
        let remote2 = AccountSettingsRemote.remoteWithApi(api)
        expect(remote1).to(beIdenticalTo(remote2))
        expect(remote1.settings).to(beIdenticalTo(remote2.settings))

        let duplicatedApi = WordPressComApi(OAuthToken: "authtoken1")
        let remote3 = AccountSettingsRemote.remoteWithApi(duplicatedApi)
        expect(remote1).to(beIdenticalTo(remote3))
    }

    func testSettingsSuccessful() {
        stub(isGetSettings()) { request in
            let stubPath = OHPathForFile("get-me-settings-v1.1.json", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type": "application/json"])
        }

        let events = subscribeToSettingsAndWait()

        expect(events.count).to(equal(2))
        expect(events[0].element).toNot(beNil())
        expect(events[1].isCompleted).to(beTrue())
        guard let settings = events[0].element else {
            XCTFail("First emitted value should be settings")
            return
        }
        expect(settings.firstName).to(equal("Jorge"))
        expect(settings.lastName).to(equal("Bernal"))
        expect(settings.displayName).to(equal("Jorge Bernal"))
        expect(settings.aboutMe).to(equal("A description of me"))
    }

    func testSettingsFail() {
        stub(isGetSettings()) { request in
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
            return OHHTTPStubsResponse(error: error)
        }

        let events = subscribeToSettingsAndWait()

        expect(events.count).to(equal(1))
        expect(events[0].isError).to(beTrue())
    }

    // MARK: - Helpers

    func settingsObservable() -> Observable<AccountSettings> {
        let api = WordPressComApi(OAuthToken: "authtoken")
        let remote = AccountSettingsRemote(api: api)
        return remote.settings
    }

    func subscribeToSettingsAndWait() -> [Event<AccountSettings>] {
        var events = [Event<AccountSettings>]()
        let expectation = expectationWithDescription("settings completed or errored")
        let subscription = settingsObservable().subscribe { (event) -> Void in
            events.append(event)

            switch event {
            case .Next(_):
                break
            case .Completed, .Error(_):
                expectation.fulfill()
            }
        }
        defer {
            subscription.dispose()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
        return events
    }

    func isGetSettings() -> OHHTTPStubsTestBlock {
        return isMethodGET() && isMeSettingsEndpoint()
    }

    func isUpdateSettings() -> OHHTTPStubsTestBlock {
        return isMethodPOST() && isMeSettingsEndpoint()
    }

    func isMeSettingsEndpoint() -> OHHTTPStubsTestBlock {
        return { request in
            return request.URL?.path?.hasSuffix("me/settings") ?? false
        }
    }


}

extension Event {
    private var isCompleted: Bool {
        if case .Completed = self {
            return true
        } else {
            return false
        }
    }

    private var isError: Bool {
        if case .Error = self {
            return true
        } else {
            return false
        }
    }
}
