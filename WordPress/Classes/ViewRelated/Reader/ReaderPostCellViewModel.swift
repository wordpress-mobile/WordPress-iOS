import Foundation

final class ReaderPostCellViewModel {
    // Header
    @Published private(set) var avatarURL: URL?
    let author: String
    let time: String

    // Content
    let title: String
    let details: String
    let imageURL: URL?

    // Footer (Buttons)
    let isBookmarked: Bool
    let isCommentsEnabled: Bool
    let commentCount: Int
    let isLikesEnabled: Bool
    let likeCount: Int
    let isLiked: Bool

    weak var viewController: ReaderStreamViewController?

    let post: ReaderPost?
    private var faviconTask: Task<Void, Never>?

    deinit {
        faviconTask?.cancel()
    }

    init(post: ReaderPost, topic: ReaderAbstractTopic?) {
        self.post = post

        let isP2 = (topic as? ReaderSiteTopic)?.isP2Type == true

        if isP2 {
            self.author = post.authorDisplayName ?? ""
        } else {
            self.author = post.blogNameForDisplay() ?? ""
        }
        self.time = post.dateForDisplay()?.toShortString() ?? "–"
        self.title = post.titleForDisplay() ?? ""
        self.details = post.contentPreviewForDisplay() ?? ""
        self.imageURL = post.featuredImageURLForDisplay()

        self.isBookmarked = post.isSavedForLater

        self.isCommentsEnabled = post.isCommentsEnabled
        self.commentCount = post.commentCount?.intValue ?? 0

        self.isLikesEnabled = post.isLikesEnabled()
        self.likeCount = post.likeCount?.intValue ?? 0
        self.isLiked = post.isLiked()

        if isP2 {
            self.avatarURL = post.authorAvatarURL.flatMap(URL.init)
        } else if let avatarURL = post.siteIconForDisplay(ofSize: Int(ReaderPostCell.avatarSize)) {
                self.avatarURL = avatarURL
        } else if let blogURL = post.blogURL.flatMap(URL.init) {
            if let faviconURL = FaviconService.shared.cachedFavicon(forURL: blogURL) {
                self.avatarURL = faviconURL
            } else {
                faviconTask = Task { @MainActor [weak self] in
                    self?.avatarURL = try? await FaviconService.shared.favicon(forURL: blogURL)
                }
            }
        }
    }

    private init() {
        self.avatarURL = URL(string: "https://picsum.photos/120/120.jpg")
        self.author = "WordPress Mobile Apps"
        self.time = "9d ago"
        self.title = "Discovering the Wonders of the Wild"
        self.details = "Lorem ipsum dolor sit amet. Non omnis quia et natus voluptatum et eligendi voluptate vel iusto fuga sit repellendus molestiae aut voluptatem blanditiis ad neque sapiente. Id galisum distinctio quo enim aperiam non veritatis vitae et ducimus rerum."
        self.imageURL = URL(string: "https://picsum.photos/1260/630.jpg")
        self.isBookmarked = false
        self.isLikesEnabled = true
        self.likeCount = 9000
        self.isCommentsEnabled = true
        self.commentCount = 213
        self.isLiked = true
        self.post = nil
    }

    static func mock() -> ReaderPostCellViewModel {
        ReaderPostCellViewModel()
    }

    // MARK: Actions

    func showSiteDetails() {
        guard let post, let viewController else { return }
        ReaderHeaderAction().execute(post: post, origin: viewController)
    }

    func toogleBookmark() {
        guard let post, let viewController else { return }
        ReaderSaveForLaterAction().execute(with: post, origin: .otherStream, viewController: viewController)
    }

    func reblog() {
        guard let post, let viewController else { return }
        ReaderReblogAction().execute(readerPost: post, origin: viewController, reblogSource: .list)
    }

    func comment() {
        guard let post, let viewController else { return }
        ReaderCommentAction().execute(post: post, origin: viewController, source: .postCard)
    }

    func toggleLike() {
        guard let post else { return }
        ReaderLikeAction().execute(with: post)
    }
}
