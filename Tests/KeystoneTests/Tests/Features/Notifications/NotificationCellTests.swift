import AVFoundation
import AsyncImageKit
import Testing
import UIKit
import WordPressData
import WordPressUI
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

/// Checks that a reused cell doesn't show the previous row's avatar.
@MainActor
struct NotificationCellAvatarTests {
    @Test func userCellReuseCancelsAvatarLoadAndShowsPlaceholder() async throws {
        // GIVEN a row whose avatar is still loading
        let cell = NoteBlockUserTableViewCell(style: .default, reuseIdentifier: nil)
        let imageView = try #require(cell.contentView.firstSubview(ofType: CircularImageView.self))
        let load = try startGatedLoad(in: imageView)

        // WHEN the cell is reused for a user with no avatar, then the load finishes
        cell.prepareForReuse()
        cell.downloadGravatarWithURL(nil)
        let placeholder = try #require(imageView.image)
        await load.finish()

        // THEN the placeholder is still shown
        #expect(imageView.image === placeholder)
    }

    @Test func headerCellReuseCancelsAvatarLoadAndShowsPlaceholder() async throws {
        // GIVEN a header whose avatar is still loading
        let cell = NoteBlockHeaderTableViewCell(style: .default, reuseIdentifier: nil)
        let imageView = try #require(cell.contentView.firstSubview(ofType: CircularImageView.self))
        let load = try startGatedLoad(in: imageView)

        // WHEN the cell is reused for a notification with no avatar, then the load finishes
        cell.prepareForReuse()
        cell.downloadAuthorAvatar(with: nil)
        let placeholder = try #require(imageView.image)
        await load.finish()

        // THEN the placeholder is still shown
        #expect(imageView.image === placeholder)
    }

    @Test func gravatarPlaceholderIsNotReplacedByEarlierLoad() async throws {
        // GIVEN an avatar that is still loading
        let imageView = UIImageView()
        let load = try startGatedLoad(in: imageView)

        // WHEN the view switches to a user with no avatar, then the load finishes
        let placeholder = makeImage(color: .gray)
        imageView.downloadGravatar(nil, placeholder: placeholder, animate: false)
        await load.finish()

        // THEN the placeholder is still shown
        #expect(imageView.image === placeholder)
    }

    private struct GatedLoad {
        let host: GatedHost
        let task: Task<Void, Never>

        @MainActor func finish() async {
            host.open()
            await task.value
        }
    }

    /// Starts loading an image into `imageView` that finishes only when `finish()` is called.
    private func startGatedLoad(in imageView: UIImageView) throws -> GatedLoad {
        let host = try GatedHost(image: makeImage(color: .red))
        let url = try #require(URL(string: "https://example.files.wordpress.com/\(UUID().uuidString).png"))
        imageView.wp.setImage(with: ImageRequest(url: url, host: host))
        return GatedLoad(host: host, task: try #require(imageView.wp.controller.task))
    }

    private func makeImage(color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
            .image { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
            }
    }
}

/// A host whose requests wait until `open()` is called, then load a PNG from disk.
@MainActor
private final class GatedHost: MediaHostProtocol, @unchecked Sendable {
    private let fileURL: URL
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(image: UIImage) throws {
        fileURL = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).png")
        try #require(image.pngData()).write(to: fileURL)
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters = []
    }

    func authenticatedRequest(for url: URL) async throws -> URLRequest {
        if !isOpen {
            await withCheckedContinuation { waiters.append($0) }
        }
        return URLRequest(url: fileURL)
    }

    func authenticatedAsset(for url: URL) async throws -> AVURLAsset {
        AVURLAsset(url: url)
    }
}
