import XCTest
import WordPressFlux

@testable import WordPress

class ActivityListViewModelTests: XCTestCase {

    // Check if `loadMore` dispatchs the correct action and params
    //
    func testLoadMore() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 0, username: "")
        let activityStoreMock = ActivityStoreMock()
        let activityListViewModel = ActivityListViewModel(site: jetpackSiteRef, store: activityStoreMock)

        activityListViewModel.loadMore()

        XCTAssertEqual(activityStoreMock.dispatchedAction, "loadMoreActivities")
        XCTAssertEqual(activityStoreMock.quantity, 20)
        XCTAssertEqual(activityStoreMock.offset, 0)
    }

    // Check if `loadMore` dispatchs the correct offset
    //
    func testLoadMoreOffset() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 0, username: "")
        let activityStoreMock = ActivityStoreMock()
        let activityListViewModel = ActivityListViewModel(site: jetpackSiteRef, store: activityStoreMock)
        activityStoreMock.state.activities[jetpackSiteRef] = [Activity.mock(), Activity.mock(), Activity.mock()]

        activityListViewModel.loadMore()

        XCTAssertEqual(activityStoreMock.dispatchedAction, "loadMoreActivities")
        XCTAssertEqual(activityStoreMock.quantity, 20)
        XCTAssertEqual(activityStoreMock.offset, 3)
    }

    // Check if `loadMore` dispatchs the correct after and before date
    //
    func testloadMoreAfterBeforeDate() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 0, username: "")
        let activityStoreMock = ActivityStoreMock()
        let activityListViewModel = ActivityListViewModel(site: jetpackSiteRef, store: activityStoreMock)
        activityStoreMock.state.activities[jetpackSiteRef] = [Activity.mock(), Activity.mock(), Activity.mock()]
        let afterDate = Date()
        let beforeDate = Date(timeIntervalSinceNow: 86400)
        activityListViewModel.refresh(after: afterDate, before: beforeDate)

        activityListViewModel.loadMore()

        XCTAssertEqual(activityStoreMock.dispatchedAction, "loadMoreActivities")
        XCTAssertEqual(activityStoreMock.afterDate, afterDate)
        XCTAssertEqual(activityStoreMock.beforeDate, beforeDate)
    }

    // Should not load more if already loading
    //
    func testLoadMoreDoesntTriggeredWhenAlreadyFetching() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 0, username: "")
        let activityStoreMock = ActivityStoreMock()
        let activityListViewModel = ActivityListViewModel(site: jetpackSiteRef, store: activityStoreMock)
        activityStoreMock.isFetching = true

        activityListViewModel.loadMore()

        XCTAssertNil(activityStoreMock.dispatchedAction)
    }

    // When filtering, remove all current activities
    //
    func testRefreshRemoveAllActivities() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 0, username: "")
        let activityStoreMock = ActivityStoreMock()
        let activityListViewModel = ActivityListViewModel(site: jetpackSiteRef, store: activityStoreMock)
        activityStoreMock.isFetching = true

        activityListViewModel.refresh(after: Date(), before: Date())

        XCTAssertEqual(activityStoreMock.dispatchedAction, "resetActivities")
    }
}

class ActivityStoreMock: ActivityStore {
    var dispatchedAction: String?
    var site: JetpackSiteRef?
    var quantity: Int?
    var offset: Int?
    var isFetching = false
    var afterDate: Date?
    var beforeDate: Date?

    override func isFetching(site: JetpackSiteRef) -> Bool {
        return isFetching
    }

    override func onDispatch(_ action: Action) {
        guard let activityAction = action as? ActivityAction else {
            return
        }

        switch activityAction {
        case .loadMoreActivities(let site, let quantity, let offset, let afterDate, let beforeDate):
            dispatchedAction = "loadMoreActivities"
            self.site = site
            self.quantity = quantity
            self.offset = offset
            self.afterDate = afterDate
            self.beforeDate = beforeDate
        case .resetActivities(let site):
            dispatchedAction = "resetActivities"
        default:
            break
        }
    }
}

extension Activity {
    static func mock() -> Activity {
        let dictionary = ["activity_id": "1", "summary": "", "content": ["text": ""], "published": "2020-11-09T13:16:43.701+00:00"] as [String: AnyObject]
        return try! Activity(dictionary: dictionary)
    }
}
