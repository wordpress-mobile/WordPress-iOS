import WordPressFlux
import XCTest

@testable import WordPress

class ActivityStoreTests: XCTestCase {
    private var dispatcher: ActionDispatcher!
    private var store: ActivityStore!
    private var activityServiceMock: ActivityServiceRemoteMock!

    override func setUp() {
        super.setUp()

        dispatcher = ActionDispatcher()
        activityServiceMock = ActivityServiceRemoteMock()
        store = ActivityStore.init(dispatcher: dispatcher, activityServiceRemote: activityServiceMock)
    }

    override func tearDown() {
        dispatcher = nil
        store = nil

        super.tearDown()
    }

    // Check if loadMoreActivities call the service with the correct params
    //
    func testLoadMoreActivities() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")

        dispatch(.loadMoreActivities(site: jetpackSiteRef, quantity: 10, offset: 20))

        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithSiteID, 9)
        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithCount, 10)
        XCTAssertEqual(activityServiceMock.getActivityForSiteCalledWithOffset, 20)
    }

    // Check if loadMoreActivities keep the activies and add the new retrieved ones
    //
    func testLoadMoreActivitiesKeepTheExistent() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 9, username: "foo")
        store.state.activities[jetpackSiteRef] = [Activity.mock()]
        activityServiceMock.activitiesToReturn = [Activity.mock(), Activity.mock()]
        activityServiceMock.hasMore = true

        dispatch(.loadMoreActivities(site: jetpackSiteRef, quantity: 10, offset: 20))

        XCTAssertEqual(store.state.activities[jetpackSiteRef]?.count, 3)
        XCTAssertTrue(store.state.hasMore)
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

    var activitiesToReturn: [Activity]?
    var hasMore = false

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

        if let activitiesToReturn = activitiesToReturn {
            success(activitiesToReturn, hasMore)
        }
    }
}
