import Testing
import UIKit
import SwiftUI
import WordPressUI

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite(.serialized)
struct AdaptiveReaderTests {
    @Test(.enabled(if: !UIDevice.isPad()))
    func articleHidesBottomTabsInRegularWidth() {
        let article = ReaderDetailViewController.controllerWithPostURL(URL(string: "https://example.com/post")!)
        let navigation = UINavigationController(rootViewController: article)
        let tabs = UITabBarController()
        tabs.mode = .tabBar
        tabs.tabs = [UITab(title: "Reader", image: nil, identifier: "reader") { _ in navigation }]
        tabs.selectedTab = tabs.tabs.first
        tabs.traitOverrides.horizontalSizeClass = .regular
        article.traitOverrides.horizontalSizeClass = .compact

        #expect(article.hidesBottomBarWhenPushed)

        tabs.traitOverrides.horizontalSizeClass = .compact
        #expect(article.hidesBottomBarWhenPushed)
    }

    @Test func initialFeedAppearsWhenMenuTopicsArrive() throws {
        try withPresenter { presenter, menu, context in
            let content = try #require(presenter.adaptiveContent)
            #expect(
                content.detailNavigationController.topViewController
                    is UIHostingController<ProgressView<EmptyView, EmptyView>>
            )

            insertRecentTopic(in: context)
            menu.onCompletion?()

            #expect(content.detailNavigationController.topViewController is ReaderStreamViewController)
            #expect(content.detailNavigationController.viewControllers.count == 1)
        }
    }

    @Test func loadingTheFeedPreservesAnArticleOpenedAboveIt() throws {
        try withPresenter { presenter, menu, context in
            let content = try #require(presenter.adaptiveContent)
            let article = UIViewController()
            content.pushDetail(article, animated: false)

            insertRecentTopic(in: context)
            menu.onCompletion?()

            #expect(content.detailNavigationController.viewControllers.first is ReaderStreamViewController)
            #expect(content.detailNavigationController.topViewController === article)
            #expect(content.detailNavigationController.viewControllers.count == 2)
        }
    }

    @Test func menuCompletionDoesNotReplaceAnotherDestination() throws {
        try withPresenter { presenter, menu, context in
            let content = try #require(presenter.adaptiveContent)
            presenter.navigate(to: .search, animated: false)
            let search = content.detailNavigationController.topViewController

            insertRecentTopic(in: context)
            menu.onCompletion?()

            #expect(content.detailNavigationController.topViewController === search)
        }
    }

    @Test func aFailedMenuRefreshStopsShowingProgress() throws {
        try withPresenter { presenter, menu, _ in
            let content = try #require(presenter.adaptiveContent)
            let progress = content.detailNavigationController.topViewController
            menu.onCompletion?()
            #expect(content.detailNavigationController.topViewController !== progress)
            #expect(
                !(content.detailNavigationController.topViewController
                    is UIHostingController<ProgressView<EmptyView, EmptyView>>)
            )
        }
    }

    private func withPresenter(
        _ body: (ReaderPresenter, DeferredReaderMenuStore, ContextManager) throws -> Void
    ) rethrows {
        let originalContext = ContextManager.overrideInstance
        let originalAccount = UserSettings.defaultDotComUUID
        let originalSelection = UserDefaults.standard.readerSidebarSelection
        let context = ContextManager.forTesting()
        ContextManager.overrideInstance = context
        UserDefaults.standard.readerSidebarSelection = .recent
        let account = AccountBuilder(context.mainContext).with(username: "adaptive-reader").build()
        UserSettings.defaultDotComUUID = account.uuid
        defer {
            UserSettings.defaultDotComUUID = originalAccount
            UserDefaults.standard.readerSidebarSelection = originalSelection
            ContextManager.overrideInstance = originalContext
        }
        let menu = DeferredReaderMenuStore()
        let model = ReaderSidebarViewModel(menuStore: menu, contextManager: context)
        let presenter = ReaderPresenter(viewModel: model)
        _ = presenter.prepareForAdaptiveTabBarPresentation()
        try body(presenter, menu, context)
    }

    private func insertRecentTopic(in context: ContextManager) {
        let topic = ReaderDefaultTopic(context: context.mainContext)
        topic.path = "https://public-api.wordpress.com/rest/v1.2/read/following"
        topic.title = "Recent"
        topic.type = ReaderDefaultTopic.TopicType
        topic.showInMenu = true
        context.saveContextAndWait(context.mainContext)
    }
}

private final class DeferredReaderMenuStore: ReaderMenuStoreProtocol {
    var onCompletion: (() -> Void)?
    func refreshMenu() {}
}
