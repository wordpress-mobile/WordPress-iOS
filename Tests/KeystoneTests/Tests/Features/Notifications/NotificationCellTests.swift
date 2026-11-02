import Testing
import UIKit
import WordPressData
@testable import WordPress

/// Checks the wiring and size-class layout the Notifications cells used to get from their xibs.
@MainActor
struct NotificationCellTests {

    @Test func buttonCellReportsTaps() {
        let cell = NoteBlockButtonTableViewCell(style: .default, reuseIdentifier: nil)
        var taps = 0
        cell.action = { taps += 1 }

        cell.button.sendActions(for: .touchUpInside)

        #expect(taps == 1)
        #expect(cell.button.isPrimary)
    }

    @Test func userCellWiresTheFollowButton() throws {
        let cell = NoteBlockUserTableViewCell(style: .default, reuseIdentifier: nil)
        cell.isFollowEnabled = true

        let button = try #require(cell.contentView.firstSubview(ofType: UIButton.self))

        #expect(button.actions(forTarget: cell, forControlEvent: .touchUpInside) == ["followWasPressed:"])
    }

    @Test func userCellRemovesAndRestoresTheFollowButton() {
        let cell = NoteBlockUserTableViewCell(style: .default, reuseIdentifier: nil)

        cell.isFollowEnabled = false
        #expect(cell.isFollowEnabled == false)

        cell.isFollowEnabled = true
        #expect(cell.isFollowEnabled)
    }

    @Test func textCellReportsLinkTaps() throws {
        let cell = NoteBlockTextTableViewCell(style: .default, reuseIdentifier: nil)
        var urls: [URL] = []
        cell.onUrlClick = { urls.append($0) }
        let url = try #require(URL(string: "https://example.com"))

        let textView = try #require(cell.contentView.firstSubview(ofType: RichTextView.self))
        textView.delegate?.textView?(UITextView(), didPressLink: url)

        #expect(urls == [url])
    }

    @Test(arguments: [
        (UIUserInterfaceSizeClass.compact, UIUserInterfaceSizeClass.regular, CGFloat(32)),
        (.regular, .compact, 32),
        (.regular, .regular, 37)
    ])
    func headerCellAvatarFollowsSizeClasses(
        horizontal: UIUserInterfaceSizeClass,
        vertical: UIUserInterfaceSizeClass,
        size: CGFloat
    ) throws {
        let cell = NoteBlockHeaderTableViewCell(style: .default, reuseIdentifier: nil)
        let window = try makeWindow(horizontal: horizontal, vertical: vertical)
        defer { window.isHidden = true }

        window.addSubview(cell)
        cell.frame = CGRect(x: 0, y: 0, width: 320, height: 70)
        cell.layoutIfNeeded()

        let avatar = try #require(cell.contentView.firstSubview(ofType: CircularImageView.self))
        #expect(avatar.frame.width == size)
    }

    @Test(arguments: [
        (UIUserInterfaceSizeClass.compact, UIUserInterfaceSizeClass.regular, CGFloat(46)),
        (.regular, .compact, 46),
        (.regular, .regular, 54)
    ])
    func userCellGravatarFollowsSizeClasses(
        horizontal: UIUserInterfaceSizeClass,
        vertical: UIUserInterfaceSizeClass,
        size: CGFloat
    ) throws {
        let cell = NoteBlockUserTableViewCell(style: .default, reuseIdentifier: nil)
        let window = try makeWindow(horizontal: horizontal, vertical: vertical)
        defer { window.isHidden = true }

        window.addSubview(cell)
        cell.frame = CGRect(x: 0, y: 0, width: 320, height: 76)
        cell.layoutIfNeeded()

        let gravatar = try #require(cell.contentView.firstSubview(ofType: CircularImageView.self))
        #expect(gravatar.frame.width == size)
    }

    @Test func likeUserCellIndentsTheSeparatorExceptOnTheLastRow() throws {
        let contextManager = ContextManager.forTesting()
        let user = LikeUser(context: contextManager.mainContext)
        user.displayName = "Jane Appleseed"
        user.username = "jane"
        let cell = LikeUserTableViewCell(style: .default, reuseIdentifier: nil)
        cell.frame = CGRect(x: 0, y: 0, width: 320, height: 80)

        cell.configure(withUser: user)
        cell.layoutIfNeeded()
        let separator = try #require(cell.contentView.subviews.last)
        #expect(separator.frame.minX == 20)

        cell.configure(withUser: user, isLastRow: true)
        cell.layoutIfNeeded()
        #expect(separator.frame.minX == 0)
    }

    @Test func labelsKeepTheXibsUserInteraction() throws {
        let userCell = NoteBlockUserTableViewCell(style: .default, reuseIdentifier: nil)
        userCell.name = "Name"
        userCell.blogTitle = "Blog"
        let userLabels = userCell.contentView.subviews(ofType: UILabel.self)
        #expect(userLabels.map(\.isUserInteractionEnabled) == [false, true])
        #expect(userLabels.allSatisfy { !$0.isOpaque })

        let likeCell = LikeUserTableViewCell(style: .default, reuseIdentifier: nil)
        let likeLabels = likeCell.contentView.subviews(ofType: UILabel.self)
        #expect(likeLabels.map(\.isUserInteractionEnabled) == [false, true])
        #expect(likeLabels.allSatisfy { !$0.isOpaque })
    }
}

/// Size classes only reach a cell through a window, so the size-class tests host the cell in one.
@MainActor
private func makeWindow(horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass) throws -> UIWindow {
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    window.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
    window.traitOverrides.horizontalSizeClass = horizontal
    window.traitOverrides.verticalSizeClass = vertical
    window.isHidden = false
    return window
}

private extension UIView {
    func firstSubview<T: UIView>(ofType type: T.Type) -> T? {
        subviews(ofType: type).first
    }

    /// Every descendant of the given type, depth first.
    func subviews<T: UIView>(ofType type: T.Type) -> [T] {
        subviews.flatMap { subview in
            [subview as? T].compactMap { $0 } + subview.subviews(ofType: type)
        }
    }
}
