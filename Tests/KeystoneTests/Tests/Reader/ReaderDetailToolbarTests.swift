import Testing
import UIKit
@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("ReaderDetailToolbar")
struct ReaderDetailToolbarTests {
    @Test("a like updates the existing toolbar items instead of recreating them")
    func likeKeepsTheSameItems() throws {
        let context = ContextManager.forTesting().mainContext
        let post = ReaderPostBuilder(context).build()
        post.isLikesEnabled = true
        post.likeCount = 2
        let viewController = UIViewController()
        let toolbar = ReaderDetailToolbar()

        toolbar.configure(for: post, in: viewController)
        let itemsBefore = try #require(viewController.toolbarItems)

        post.isLiked = true
        post.likeCount = 1234

        let itemsAfter = try #require(viewController.toolbarItems)
        #expect(itemsAfter.count == itemsBefore.count)
        #expect(zip(itemsBefore, itemsAfter).allSatisfy { $0 === $1 })

        let likeButton = try #require(itemsAfter.last?.customView as? UIButton)
        #expect(likeButton.configuration?.title == 1234.formatted(.number.notation(.compactName)))
    }

    @Test("the like button resizes when its count gets shorter")
    func likeButtonResizesToItsCount() throws {
        let context = ContextManager.forTesting().mainContext
        let post = ReaderPostBuilder(context).build()
        post.isLikesEnabled = true
        post.likeCount = 1234
        let viewController = UIViewController()
        let toolbar = ReaderDetailToolbar()

        toolbar.configure(for: post, in: viewController)
        let likeButton = try #require(viewController.toolbarItems?.last?.customView as? UIButton)
        let wideWidth = likeButton.frame.width

        post.likeCount = 2

        #expect(likeButton.frame.width < wideWidth)
        #expect(likeButton.frame.width == likeButton.intrinsicContentSize.width)
    }
}
