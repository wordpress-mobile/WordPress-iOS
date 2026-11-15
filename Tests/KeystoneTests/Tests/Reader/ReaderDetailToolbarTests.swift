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

        let likeButton = try #require(buttons(in: itemsAfter).last)
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
        let likeButton = try #require(buttons(in: viewController.toolbarItems).last)
        let wideWidth = width(of: likeButton)

        post.likeCount = 2

        #expect(width(of: likeButton) < wideWidth)
        #expect(abs(width(of: likeButton) - likeButton.sizeThatFits(UIView.layoutFittingCompressedSize).width) < 1)
    }

    @Test("the like button grows when its count gets slightly wider")
    func likeButtonGrowsToItsCount() throws {
        let context = ContextManager.forTesting().mainContext
        let post = ReaderPostBuilder(context).build()
        post.isLikesEnabled = true
        post.likeCount = 1
        let viewController = UIViewController()
        let toolbar = ReaderDetailToolbar()

        toolbar.configure(for: post, in: viewController)
        let likeButton = try #require(buttons(in: viewController.toolbarItems).last)
        let narrowWidth = width(of: likeButton)

        post.likeCount = 9

        #expect(width(of: likeButton) > narrowWidth)
        #expect(abs(width(of: likeButton) - likeButton.sizeThatFits(UIView.layoutFittingCompressedSize).width) < 1)
    }

    @Test("the toolbar is rebuilt when the comment button has to appear")
    func firstCommentAddsTheCommentButton() throws {
        let context = ContextManager.forTesting().mainContext
        let post = ReaderPostBuilder(context).build()
        post.isWPCom = true
        post.isLikesEnabled = false
        post.commentsOpen = false
        post.commentCount = 0
        let viewController = UIViewController()
        let toolbar = ReaderDetailToolbar(isLoggedIn: { true })

        toolbar.configure(for: post, in: viewController)
        #expect(buttons(in: viewController.toolbarItems).count == 2) // Save and reblog

        post.commentCount = 1

        let buttonsAfter = buttons(in: viewController.toolbarItems)
        #expect(buttonsAfter.count == 3)
        #expect(buttonsAfter.last?.configuration?.title == 1.formatted(.number.notation(.compactName)))
    }

    @Test(
        "the reblog button is shown only when the post can be reblogged",
        arguments: [
            (isLoggedIn: true, isBlogPrivate: false, showsReblog: true),
            (isLoggedIn: true, isBlogPrivate: true, showsReblog: false),
            (isLoggedIn: false, isBlogPrivate: false, showsReblog: false)
        ]
    )
    func reblogButtonVisibility(isLoggedIn: Bool, isBlogPrivate: Bool, showsReblog: Bool) throws {
        let context = ContextManager.forTesting().mainContext
        let post = ReaderPostBuilder(context).build()
        post.isBlogPrivate = isBlogPrivate
        post.isLikesEnabled = false
        post.commentsOpen = false
        post.commentCount = 0
        let viewController = UIViewController()
        let toolbar = ReaderDetailToolbar(isLoggedIn: { isLoggedIn })

        toolbar.configure(for: post, in: viewController)

        let labels = buttons(in: viewController.toolbarItems).map(\.accessibilityLabel)
        #expect(labels.contains("Reblog post") == showsReblog)
        #expect(labels.count == (showsReblog ? 2 : 1)) // Save, and reblog when shown
    }

    @Test("a frosted capsule fits its buttons after a count changes width")
    func capsuleFitsItsButtons() throws {
        guard #available(iOS 26, *) else { return }

        let context = ContextManager.forTesting().mainContext
        let post = ReaderPostBuilder(context).build()
        post.isLikesEnabled = true
        post.likeCount = 3
        let viewController = UIViewController()
        let toolbar = ReaderDetailToolbar()

        toolbar.configure(for: post, in: viewController)
        let capsule = try #require(viewController.toolbarItems?.last?.customView)
        let narrowWidth = capsule.intrinsicContentSize.width

        post.likeCount = 1234

        #expect(capsule.intrinsicContentSize.width > narrowWidth)
        #expect(capsule.frame.width == capsule.intrinsicContentSize.width)
        for button in buttons(in: capsule) {
            #expect(width(of: button) >= button.sizeThatFits(UIView.layoutFittingCompressedSize).width)
        }

        post.likeCount = 3

        #expect(capsule.intrinsicContentSize.width == narrowWidth)
        #expect(capsule.frame.width == narrowWidth)
    }

    // MARK: - Helpers

    /// The toolbar's buttons in order, whether each is its own item or they share a frosted capsule (iOS 26+).
    private func buttons(in items: [UIBarButtonItem]?) -> [UIButton] {
        (items ?? []).compactMap(\.customView).flatMap { buttons(in: $0) }
    }

    private func buttons(in view: UIView) -> [UIButton] {
        if let button = view as? UIButton {
            return [button]
        }
        return view.subviews.flatMap { buttons(in: $0) }
    }

    /// The width the toolbar gives a button: its pinned width on a frosted capsule (iOS 26+), or its frame.
    private func width(of button: UIButton) -> CGFloat {
        let pinned = button.constraints.first { $0.firstAttribute == .width && $0.secondItem == nil }
        return pinned?.constant ?? button.frame.width
    }
}
