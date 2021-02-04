import XCTest
import WordPressFlux

@testable import WordPress

class ActivityListViewModelTests: XCTestCase {

    let activityListConfiguration = ActivityListConfiguration(
        identifier: "identifier",
        title: "Title",
        loadingTitle: "Loading Activities...",
        noActivitiesTitle: "No activity yet",
        noActivitiesSubtitle: "When you make changes to your site you'll be able to see your activity history here.",
        noMatchingTitle: "No matching events found.",
        noMatchingSubtitle: "Try adjusting your date range or activity type filters",
        filterbarRangeButtonTapped: .activitylogFilterbarRangeButtonTapped,
        filterbarSelectRange: .activitylogFilterbarSelectRange,
        filterbarResetRange: .activitylogFilterbarResetRange,
        numberOfItemsPerPage: 20
    )

    // Check if `loadMore` dispatchs the correct action and params
    //
    func testLoadMore() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 0, username: "")
        let activityStoreMock = ActivityStoreMock()
        let activityListViewModel = ActivityListViewModel(site: jetpackSiteRef, store: activityStoreMock, configuration: activityListConfiguration)

        activityListViewModel.loadMore()

        XCTAssertEqual(activityStoreMock.dispatchedAction, "loadMoreActivities")
        XCTAssertEqual(activityStoreMock.quantity, 20)
        XCTAssertEqual(activityStoreMock.offset, 20)
    }

    // Check if `loadMore` dispatchs the correct offset
    //
    func testLoadMoreOffset() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 0, username: "")
        let activityStoreMock = ActivityStoreMock()
        let activityListViewModel = ActivityListViewModel(site: jetpackSiteRef, store: activityStoreMock, configuration: activityListConfiguration)
        activityStoreMock.state.activities[jetpackSiteRef] = [Activity.mock(), Activity.mock(), Activity.mock()]

        activityListViewModel.loadMore()
        activityListViewModel.loadMore()

        XCTAssertEqual(activityStoreMock.dispatchedAction, "loadMoreActivities")
        XCTAssertEqual(activityStoreMock.quantity, 20)
        XCTAssertEqual(activityStoreMock.offset, 40)
    }

    // Check if `loadMore` dispatchs the correct after/before date and groups
    //
    func testLoadMoreAfterBeforeDate() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 0, username: "")
        let activityStoreMock = ActivityStoreMock()
        let activityListViewModel = ActivityListViewModel(site: jetpackSiteRef, store: activityStoreMock, configuration: activityListConfiguration)
        activityStoreMock.state.activities[jetpackSiteRef] = [Activity.mock(), Activity.mock(), Activity.mock()]
        let afterDate = Date()
        let beforeDate = Date(timeIntervalSinceNow: 86400)
        let activityGroup = ActivityGroup.mock()
        activityListViewModel.refresh(after: afterDate, before: beforeDate, group: [activityGroup])

        activityListViewModel.loadMore()

        XCTAssertEqual(activityStoreMock.dispatchedAction, "loadMoreActivities")
        XCTAssertEqual(activityStoreMock.afterDate, afterDate)
        XCTAssertEqual(activityStoreMock.beforeDate, beforeDate)
        XCTAssertEqual(activityStoreMock.group, [activityGroup.key])
    }

    // Should not load more if already loading
    //
    func testLoadMoreDoesntTriggeredWhenAlreadyFetching() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 0, username: "")
        let activityStoreMock = ActivityStoreMock()
        let activityListViewModel = ActivityListViewModel(site: jetpackSiteRef, store: activityStoreMock, configuration: activityListConfiguration)
        activityStoreMock.isFetching = true

        activityListViewModel.loadMore()

        XCTAssertNil(activityStoreMock.dispatchedAction)
    }

    // When filtering, remove all current activities
    //
    func testRefreshRemoveAllActivities() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 0, username: "")
        let activityStoreMock = ActivityStoreMock()
        let activityListViewModel = ActivityListViewModel(site: jetpackSiteRef, store: activityStoreMock, configuration: activityListConfiguration)
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
    var group: [String]?

    override func isFetchingActivities(site: JetpackSiteRef) -> Bool {
        return isFetching
    }

    override func onDispatch(_ action: Action) {
        guard let activityAction = action as? ActivityAction else {
            return
        }

        switch activityAction {
        case .loadMoreActivities(let site, let quantity, let offset, let afterDate, let beforeDate, let group):
            dispatchedAction = "loadMoreActivities"
            self.site = site
            self.quantity = quantity
            self.offset = offset
            self.afterDate = afterDate
            self.beforeDate = beforeDate
            self.group = group
        case .resetActivities:
            dispatchedAction = "resetActivities"
        default:
            break
        }
    }
}

extension Activity {
    static func mock(isRewindable: Bool = false) -> Activity {
        let dictionary = ["activity_id": "1", "summary": "", "is_rewindable": isRewindable, "rewind_id": "1", "content": ["text": ""], "published": "2020-11-09T13:16:43.701+00:00"] as [String: AnyObject]
        return try! Activity(dictionary: dictionary)
    }
}
