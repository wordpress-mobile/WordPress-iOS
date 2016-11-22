import XCTest
@testable import WordPress

class ReaderSiteServiceRemoteTests: XCTestCase {

    let mockRemoteApi = MockWordPressComRestApi()
    var readerSiteServiceRemote: ReaderSiteServiceRemote!

    override func setUp() {
        super.setUp()
        readerSiteServiceRemote = ReaderSiteServiceRemote(wordPressComRestApi: mockRemoteApi)
    }

    func testFetchFollowedSitesPath() {

        let expectedPath = "v1.1/read/following/mine?meta=site,feed"
        readerSiteServiceRemote.fetchFollowedSitesWithSuccess({_ in}, failure: {_ in})
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testFetchFollowedSites() {

        let response = ["subscriptions" : [["ID" : 1], ["ID" : 2]]]
        var sites = [RemoteReaderSite]()
        readerSiteServiceRemote.fetchFollowedSitesWithSuccess({
                sites = $0
            }, failure: {_ in})
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertFalse(sites.isEmpty, "Should have at least one site")
    }

    func testFollowSiteWithIDPath() {

        let expectedPath = "v1.1/sites/1/follows/new"
        readerSiteServiceRemote.followSiteWithID(1, success:{}, failure: {_ in})
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testFollowSiteWithID() {

        var success = false
        let response = [String : AnyObject]()
        readerSiteServiceRemote.followSiteWithID(1, success:{
            success = true
            }, failure: {_ in})
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }

    func testUnfollowSiteWithIDPath() {

        let expectedPath = "v1.1/sites/1/follows/mine/delete"
        readerSiteServiceRemote.unfollowSiteWithID(1, success:{}, failure: {_ in})
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testUnfollowSiteWithID() {

        var success = false
        let response = [String : AnyObject]()
        readerSiteServiceRemote.unfollowSiteWithID(1, success:{
            success = true
            }, failure: {_ in})
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }

    func testFollowSiteAtURLPath() {

        let url = "http://www.wordpress.com"
        let expectedPath = "v1.1/read/following/mine/new?url=\(url)"
        readerSiteServiceRemote.followSiteAtURL(url, success:{}, failure: {_ in})
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testFollowSiteAtURL() {

        let response = ["subscribed" : true]
        var success = false
        let url = "http://www.wordpress.com"
        readerSiteServiceRemote.followSiteAtURL(url, success:{
            success = true
            }, failure: {_ in})
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }

    func testFollowSiteAtURLFailure() {

        let response = ["subscribed" : false]
        var failure = false
        let url = "http://www.wordpress.com"
        readerSiteServiceRemote.followSiteAtURL(url, success:{}, failure: { _ in
            failure = true
        })
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(failure)
    }

    func testUnfollowSiteAtURLPath() {

        let url = "http://www.wordpress.com"
        let expectedPath = "v1.1/read/following/mine/delete?url=\(url)"
        readerSiteServiceRemote.unfollowSiteAtURL(url, success:{}, failure: {_ in})
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testUnfollowSiteAtURL() {

        let response = ["subscribed" : false]
        var success = false
        let url = "http://www.wordpress.com"
        readerSiteServiceRemote.unfollowSiteAtURL(url, success:{
            success = true
            }, failure: {_ in})
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }

    func testUnfollowSiteAtURLFailure() {

        let response = ["subscribed" : true]
        var failure = false
        let url = "http://www.wordpress.com"
        readerSiteServiceRemote.unfollowSiteAtURL(url, success:{}, failure: { _ in
            failure = true
        })
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(failure)
    }

    func testFindSiteIDForURLPath() {

        let url = NSURL(string: "http://www.wordpress.com")!
        let expectedPath = "v1.1/sites/\(url.host!)"
        readerSiteServiceRemote.findSiteIDForURL(url, success:{_ in}, failure: {_ in})
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testFindSiteIDForURLWithNoHost() {

        let response = [String : AnyObject]()
        var failure = false
        let url = NSURL(string: "http://")!
        readerSiteServiceRemote.findSiteIDForURL(url, success:{_ in}, failure: { _ in
            failure = true
        })
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(failure)
    }

    func testFindSiteIDForURL() {

        let response = ["ID" : 1]
        var siteID : UInt = 0
        let url = NSURL(string: "http://www.wordpress.com")!
        readerSiteServiceRemote.findSiteIDForURL(url, success:{
            siteID = $0
        }, failure: {_ in})
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(siteID != 0)
    }

    func testSubscribedToSiteByIDPath() {

        let expectedPath = "v1.1/sites/1/follows/mine"
        readerSiteServiceRemote.checkSubscribedToSiteByID(1, success:{_ in}, failure: {_ in})
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testIsSubscribedToSiteByID() {

        var subscribed = false
        let response = ["is_following" : true]
        readerSiteServiceRemote.checkSubscribedToSiteByID(1, success:{
            subscribed = $0
            }, failure: {_ in})
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(subscribed)
    }

    func testIsNotSubscribedToSiteByID() {

        var subscribed = true
        let response = ["is_following" : false]
        readerSiteServiceRemote.checkSubscribedToSiteByID(1, success:{
            subscribed = $0
            }, failure: {_ in})
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertFalse(subscribed)
    }

    func testSubscribedToFeedByURLPath() {

        let url = NSURL(string: "http://www.wordpress.com")!
        let expectedPath = "v1.1/read/following/mine"
        readerSiteServiceRemote.checkSubscribedToFeedByURL(url, success:{_ in}, failure: {_ in})
        XCTAssertTrue(mockRemoteApi.getMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testSubscribedToFeedByURL() {

        let url = NSURL(string: "http://www.wordpress.com")!
        var subscribed = false
        let response = url.absoluteString!
        readerSiteServiceRemote.checkSubscribedToFeedByURL(url, success:{
            subscribed = $0
            }, failure: {_ in})
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(subscribed)
    }

    func testNotSubscribedToFeedByURL() {

        let url = NSURL(string: "http://www.wordpress.com")!
        var subscribed = true
        let response = "http://www.gravatar.com"
        readerSiteServiceRemote.checkSubscribedToFeedByURL(url, success:{
            subscribed = $0
        }, failure: {_ in})
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertFalse(subscribed)
    }

    func testFlagSiteWithIDPath() {

        let expectedPath = "v1.1/me/block/sites/1/delete"
        readerSiteServiceRemote.flagSiteWithID(1, asBlocked:false, success:{}, failure: {_ in})
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testFlagBlockedSiteWithIDPath() {

        let expectedPath = "v1.1/me/block/sites/1/new"
        readerSiteServiceRemote.flagSiteWithID(1, asBlocked:true, success:{}, failure: {_ in})
        XCTAssertTrue(mockRemoteApi.postMethodCalled, "Wrong method")
        XCTAssertEqual(mockRemoteApi.URLStringPassedIn, expectedPath, "Wrong path")
    }

    func testFlagSiteWithID() {

        let response = ["success" : true]
        var success = false
        readerSiteServiceRemote.flagSiteWithID(1, asBlocked:false, success:{
            success = true
            }, failure: {_ in})
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(success)
    }

    func testFlagSiteWithIDFailure () {

        let response = ["success" : false]
        var failure = false
        readerSiteServiceRemote.flagSiteWithID(1, asBlocked:false, success:{}, failure: { _ in
            failure = true
        })
        mockRemoteApi.successBlockPassedIn?(response, NSHTTPURLResponse())
        XCTAssertTrue(failure)
    }
}
