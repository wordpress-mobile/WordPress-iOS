import WordPressFlux
import XCTest

@testable import WordPress
@testable import WordPressKit

class ActivityStoreTests: XCTestCase {
    private var dispatcher: ActionDispatcher!
    private var store: ActivityStore!
    private var activityServiceMock: ActivityServiceRemoteMock!
    private var backupServiceMock: JetpackBackupServiceMock!

    override func setUp() {
        super.setUp()

        dispatcher = ActionDispatcher()
        activityServiceMock = ActivityServiceRemoteMock()
        backupServiceMock = JetpackBackupServiceMock()
        store = ActivityStore(dispatcher: dispatcher, activityServiceRemote: activityServiceMock, backupService: backupServiceMock)
    }

    override func tearDown() {
        dispatcher = nil
        store = nil

        super.tearDown()
    }

    // Check if refreshActivities call the service with the correct after and before date
    //
    func testRefreshActivities() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")
        let afterDate = Date()
        let beforeDate = Date(timeIntervalSinceNow: 86400)
        let group = ["post"]

        dispatch(.refreshActivities(site: jetpackSiteRef, quantity: 10, afterDate: afterDate, beforeDate: beforeDate, group: group))

        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithAfterDate, afterDate)
        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithBeforeDate, beforeDate)
        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithGroup, group)
    }

    // Check if loadMoreActivities call the service with the correct params
    //
    func testLoadMoreActivities() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")
        let afterDate = Date()
        let beforeDate = Date(timeIntervalSinceNow: 86400)
        let group = ["post", "user"]

        dispatch(.loadMoreActivities(site: jetpackSiteRef, quantity: 10, offset: 20, afterDate: afterDate, beforeDate: beforeDate, group: group))

        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithSiteID, 9)
        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithCount, 10)
        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithOffset, 20)
        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithAfterDate, afterDate)
        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithBeforeDate, beforeDate)
        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithGroup, group)
    }

    // Check if loadMoreActivities keep the activies and add the new retrieved ones
    //
    func testLoadMoreActivitiesKeepTheExistent() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")
        store.state.activities[jetpackSiteRef] = [Activity.mock()]
        activityServiceMock.activitiesToReturn = [Activity.mock(), Activity.mock()]
        activityServiceMock.hasMore = true

        dispatch(.loadMoreActivities(site: jetpackSiteRef, quantity: 10, offset: 20, afterDate: nil, beforeDate: nil, group: []))

        XCTAssertEqual(store.state.activities[jetpackSiteRef]?.count, 3)
        XCTAssertTrue(store.state.hasMore)
    }

    // resetActivities remove all activities
    //
    func testResetActivities() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")
        store.state.activities[jetpackSiteRef] = [Activity.mock()]
        activityServiceMock.activitiesToReturn = [Activity.mock(), Activity.mock()]
        activityServiceMock.hasMore = true

        dispatch(.resetActivities(site: jetpackSiteRef))

        XCTAssertTrue(store.state.activities[jetpackSiteRef]!.isEmpty)
        XCTAssertFalse(store.state.fetchingActivities[jetpackSiteRef]!)
        XCTAssertFalse(store.state.hasMore)
    }

    // Check if loadMoreActivities keep the activies and add the new retrieved ones
    //
    func testReturnOnlyRewindableActivities() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")
        store.state.activities[jetpackSiteRef] = [Activity.mock()]
        activityServiceMock.activitiesToReturn = [Activity.mock(isRewindable: true), Activity.mock()]
        activityServiceMock.hasMore = true

        store.onlyRestorableItems = true
        dispatch(.loadMoreActivities(site: jetpackSiteRef, quantity: 10, offset: 20, afterDate: nil, beforeDate: nil, group: []))

        XCTAssertEqual(store.state.activities[jetpackSiteRef]?.filter { $0.isRewindable }.count, 1)
    }

    // refreshGroups call the service with the correct params
    //
    func testRefreshGroups() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")
        let afterDate = Date()
        let beforeDate = Date(timeIntervalSinceNow: 86400)

        dispatch(.refreshGroups(site: jetpackSiteRef, afterDate: afterDate, beforeDate: beforeDate))

        XCTAssertEqual(activityServiceMock.getActivityGroupsForSiteCalledWithSiteID, 9)
        XCTAssertEqual(activityServiceMock.getActivityGroupsForSiteCalledWithAfterDate, afterDate)
        XCTAssertEqual(activityServiceMock.getActivityGroupsForSiteCalledWithBeforeDate, beforeDate)
    }

    // refreshGroups stores the returned groups
    //
    func testRefreshGroupsStoreGroups() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")
        activityServiceMock.groupsToReturn = [try! ActivityGroup("post", dictionary: ["name": "Posts and Pages", "count": 5] as [String: AnyObject])]

        dispatch(.refreshGroups(site: jetpackSiteRef, afterDate: nil, beforeDate: nil))

        XCTAssertEqual(store.state.groups[jetpackSiteRef]?.count, 1)
        XCTAssertTrue(store.state.groups[jetpackSiteRef]!.contains(where: { $0.key == "post" && $0.name == "Posts and Pages" && $0.count == 5}))
    }

    // refreshGroups does not produce multiple requests
    //
    func testRefreshGroupsDoesNotProduceMultipleRequests() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")

        dispatch(.refreshGroups(site: jetpackSiteRef, afterDate: nil, beforeDate: nil))
        dispatch(.refreshGroups(site: jetpackSiteRef, afterDate: nil, beforeDate: nil))

        XCTAssertEqual(activityServiceMock.getActivityGroupsForSiteCalledTimes, 1)
    }

    // When a previous request for Activity types has suceeded, return the cached groups
    //
    func testRefreshGroupsUseCache() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")
        activityServiceMock.groupsToReturn = [try! ActivityGroup("post", dictionary: ["name": "Posts and Pages", "count": 5] as [String: AnyObject])]

        dispatch(.refreshGroups(site: jetpackSiteRef, afterDate: nil, beforeDate: nil))
        dispatch(.refreshGroups(site: jetpackSiteRef, afterDate: nil, beforeDate: nil))

        XCTAssertEqual(activityServiceMock.getActivityGroupsForSiteCalledTimes, 1)
        XCTAssertTrue(store.state.groups[jetpackSiteRef]!.contains(where: { $0.key == "post" && $0.name == "Posts and Pages" && $0.count == 5}))
    }

    // Request groups endpoint again if the cache expired
    //
    func testRefreshGroupsRequestsAgainIfTheFirstSucceeds() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")
        activityServiceMock.groupsToReturn = [try! ActivityGroup("post", dictionary: ["name": "Posts and Pages", "count": 5] as [String: AnyObject])]
        dispatch(.refreshGroups(site: jetpackSiteRef, afterDate: nil, beforeDate: nil))

        dispatch(.resetGroups(site: jetpackSiteRef))
        dispatch(.refreshGroups(site: jetpackSiteRef, afterDate: Date(), beforeDate: nil))

        XCTAssertEqual(activityServiceMock.getActivityGroupsForSiteCalledTimes, 2)
    }

    // MARK: - Backup Status

    // Query for backup status call the service
    //
    func testBackupStatusQueryCallsService() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")

        _ = store.query(.backupStatus(site: jetpackSiteRef))
        store.processQueries()

        XCTAssertEqual(backupServiceMock.didCallGetAllBackupStatusWithSite, jetpackSiteRef)
    }

    // MARK: - Helpers

    private func dispatch(_ action: ActivityAction) {
        dispatcher.dispatch(action)
    }
}

class ActivityServiceRemoteMock: ActivityServiceRemote {
    var getActivityForSiteCalledWithSiteID: Int?
    var getActivityForSiteCalledWithOffset: Int?
    var getActivityForSiteCalledWithCount: Int?
    var getActivityForSiteCalledWithAfterDate: Date?
    var getActivityForSiteCalledWithBeforeDate: Date?
    var getActivityForSiteCalledWithGroup: [String]?

    var getActivityGroupsForSiteCalledWithSiteID: Int?
    var getActivityGroupsForSiteCalledWithAfterDate: Date?
    var getActivityGroupsForSiteCalledWithBeforeDate: Date?
    var getActivityGroupsForSiteCalledTimes = 0

    var activitiesToReturn: [Activity]?
    var hasMore = false

    var groupsToReturn: [ActivityGroup]?

    override func getActivityForSite(_ siteID: Int,
                                     offset: Int = 0,
                                     count: Int,
                                     after: Date? = nil,
                                     before: Date? = nil,
                                     group: [String] = [],
                                     success: @escaping (_ activities: [Activity], _ hasMore: Bool) -> Void,
                                     failure: @escaping (Error) -> Void) {
        getActivityForSiteCalledWithSiteID = siteID
        getActivityForSiteCalledWithCount = count
        getActivityForSiteCalledWithOffset = offset
        getActivityForSiteCalledWithAfterDate = after
        getActivityForSiteCalledWithBeforeDate = before
        getActivityForSiteCalledWithGroup = group

        if let activitiesToReturn = activitiesToReturn {
            success(activitiesToReturn, hasMore)
        }
    }

    override func getActivityGroupsForSite(_ siteID: Int, after: Date? = nil, before: Date? = nil, success: @escaping ([ActivityGroup]) -> Void, failure: @escaping (Error) -> Void) {
        getActivityGroupsForSiteCalledWithSiteID = siteID
        getActivityGroupsForSiteCalledWithAfterDate = after
        getActivityGroupsForSiteCalledWithBeforeDate = before
        getActivityGroupsForSiteCalledTimes += 1

        if let groupsToReturn = groupsToReturn {
            success(groupsToReturn)
        }
    }

    override func getRewindStatus(_ siteID: Int, success: @escaping (RewindStatus) -> Void, failure: @escaping (Error) -> Void) {

    }
}

extension ActivityGroup {
    class func mock() -> ActivityGroup {
        try! ActivityGroup("post", dictionary: ["name": "Posts and Pages", "count": 5] as [String: AnyObject])
    }
}

class JetpackBackupServiceMock: JetpackBackupService {
    var didCallGetAllBackupStatusWithSite: JetpackSiteRef?

    init() {
        super.init(managedObjectContext: TestContextManager.sharedInstance().mainContext)
    }

    override func getAllBackupStatus(for site: JetpackSiteRef, success: @escaping ([JetpackBackup]) -> Void, failure: @escaping (Error) -> Void) {
        didCallGetAllBackupStatusWithSite = site

        let jetpackBackup = JetpackBackup(backupPoint: Date(), downloadID: 100, rewindID: "", startedAt: Date(), progress: 10, downloadCount: 0, url: "", validUntil: nil)
        success([jetpackBackup])
    }
}
