import XCTest
import WordPressFlux

@testable import WordPress

class ActivityListViewModelTests: XCTestCase {

    // Check if `loadMore` dispatchs the correct action and params
    //
    func testLoadMore() {
        let jetpackSiteRef = JetpackSiteRef.mock(siteID: 0, username: "")
        let activityStoreMock = ActivityStoreMock()
        let activityListViewModel = ActivityListViewModel.init(site: jetpackSiteRef, store: activityStoreMock)

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
        let activityListViewModel = ActivityListViewModel.init(site: jetpackSiteRef, store: activityStoreMock)
        activityStoreMock.state.activities[jetpackSiteRef] = [mockedActivity(), mockedActivity(), mockedActivity()]

        activityListViewModel.loadMore()

        XCTAssertEqual(activityStoreMock.dispatchedAction, "loadMoreActivities")
        XCTAssertEqual(activityStoreMock.quantity, 20)
        XCTAssertEqual(activityStoreMock.offset, 3)
    }

    private func mockedActivity() -> Activity {
        let dictionary = ["activity_id": "1", "summary": "", "content": ["text": ""], "published": "2020-11-09T13:16:43.701+00:00"] as [String : AnyObject]
        return try! Activity(dictionary: dictionary)
    }
}

class ActivityStoreMock: ActivityStore {
    var dispatchedAction: String?
    var site: JetpackSiteRef?
    var quantity: Int?
    var offset: Int?

    override func onDispatch(_ action: Action) {
        guard let activityAction = action as? ActivityAction else {
            return
        }

        switch activityAction {
        case .loadMoreActivities(let site, let quantity, let offset):
            dispatchedAction = "loadMoreActivities"
            self.site = site
            self.quantity = quantity
            self.offset = offset
        default:
            break
        }
    }
}
