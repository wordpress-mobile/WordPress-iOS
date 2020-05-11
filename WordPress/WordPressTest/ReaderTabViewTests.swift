@testable import WordPress
import XCTest


class ReaderTabViewTests: XCTestCase {

    func testRefreshTabBarWithHiddenButtons() {
        // Given
        let store = MockItemsStore()
        let context = MockContext.getContext()!
        let topic = ReaderAbstractTopic(context: context)

        let viewModel = ReaderTabViewModel(readerContentFactory: readerContentControllerFactory(_:),
                                           searchNavigationFactory: { },
                                           tabItemsStore: store,
                                           settingsPresenter: MockSettingsPresenter())
        let view = ReaderTabView(viewModel: viewModel)
        store.newItems = [ReaderTabItem(ReaderContent(topic: topic))]
        // When
        store.getItems()
        // Then
        guard let buttonsStackView = view.subviews.first!.subviews.first(where: {
            $0 is UIStackView && $0.isHidden
        }) else {
            XCTFail("Buttons stack view should be hidden")
            return
        }
        validateButtonsStackView(buttonsStackView)
    }

    func testRefreshTabBarWithNoHiddenButtons() {
        // Given
        let store = MockItemsStore()
        let context = MockContext.getContext()!
        let topic = ReaderAbstractTopic(context: context)
        topic.path = "myPath/read/following"

        let viewModel = ReaderTabViewModel(readerContentFactory: readerContentControllerFactory(_:),
                                           searchNavigationFactory: { },
                                           tabItemsStore: store,
                                           settingsPresenter: MockSettingsPresenter())
        let view = ReaderTabView(viewModel: viewModel)
        store.newItems = [ReaderTabItem(ReaderContent(topic: topic))]
        // When
        store.getItems()
        // Then
        guard let buttonsStackView = view.subviews.first!.subviews.first(where: {
            $0 is UIStackView && !$0.isHidden
        }) else {
            XCTFail("Buttons stack view should not be hidden")
            return
        }
        validateButtonsStackView(buttonsStackView)
    }

    func testSelectIndex() {
        // Given
        let store = MockItemsStore()
        let context = MockContext.getContext()!
        let topic = ReaderAbstractTopic(context: context)
        topic.path = "myPath/read/following"

        let viewModel = ReaderTabViewModel(readerContentFactory: readerContentControllerFactory(_:),
                                           searchNavigationFactory: { },
                                           tabItemsStore: store,
                                           settingsPresenter: MockSettingsPresenter())
        let view = ReaderTabView(viewModel: viewModel)
        store.newItems = [ReaderTabItem(ReaderContent(topic: nil, contentType: .saved)), ReaderTabItem(ReaderContent(topic: topic))]
        store.getItems()
        // initial tab is not a 'Following' tab, buttons should be hidden
        guard let _ = view.subviews.first!.subviews.first(where: {
            $0 is UIStackView && $0.isHidden
        }) else {
            XCTFail("Buttons stack view should be hidden")
            return
        }
        // When
        viewModel.switchToTab(where: { ReaderHelpers.topicIsFollowing($0) })
        // Then
        // switched to a 'Following' tab, button should not be hidden
        guard let buttonsStackView = view.subviews.first!.subviews.first(where: {
            $0 is UIStackView && !$0.isHidden
        }) else {
            XCTFail("Buttons stack view should not be hidden")
            return
        }
        validateButtonsStackView(buttonsStackView)
    }

}


// MARK: - Helper methods
extension ReaderTabViewTests {

    private func validateButtonsStackView(_ view: UIView) {
        XCTAssert(view is UIStackView)
        XCTAssertEqual(view.subviews.count, 4)
        XCTAssertTrue(view.subviews.contains(where: { $0 is PostMetaButton }))
    }

    private func readerContentControllerFactory(_ content: ReaderContent) -> ReaderContentViewController {
        return MockContentController()
    }
}
