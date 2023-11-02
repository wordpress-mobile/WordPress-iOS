
struct ReaderPostCardCellViewModel {

    // MARK: - Properties

    var siteIconURL: URL? {
        let scale = WordPressAppDelegate.shared?.window?.screen.scale ?? 1.0
        let size = ReaderPostCardCell.Constants.iconImageSize * scale
        return contentProvider.siteIconForDisplay(ofSize: Int(size))
    }

    private var isRTL: Bool {
        UIView.userInterfaceLayoutDirection(for: .unspecified) == .rightToLeft
    }

    var siteTitle: String? {
        if let post = contentProvider as? ReaderPost, post.isP2Type(), let author = contentProvider.authorForDisplay() {
            let strings = [author, contentProvider.blogNameForDisplay?()].compactMap { $0 }
            return isRTL ? strings.reversed().joined(separator: " ◂ ") : strings.joined(separator: " ▸ ")
        }

        return contentProvider.blogNameForDisplay?()
    }

    var shortPostDate: String? {
        contentProvider.dateForDisplay()?.toShortString()
    }

    var postDate: String? {
        guard let shortPostDate else {
            return nil
        }
        let postDateFormat = isRTL ? "%@ •" : "• %@"
        return siteTitle != nil ? String(format: postDateFormat, shortPostDate) : shortPostDate
    }

    var postTitle: String? {
        contentProvider.titleForDisplay()
    }

    private var featuredImageIdealSize: CGSize? {
        guard let window = WordPressAppDelegate.shared?.window else {
            return nil
        }

        let windowWidth = window.screen.bounds.width
        let safeAreaOffset = window.safeAreaInsets.left + window.safeAreaInsets.right
        let width = windowWidth - safeAreaOffset - ReaderPostCardCell.Constants.ContentStackView.margins * 2
        let height = width * ReaderPostCardCell.Constants.FeaturedImage.heightAspectMultiplier
        return CGSize(width: width, height: height)
    }

    var postSummary: String? {
        contentProvider.contentPreviewForDisplay()
    }

    var commentCount: String? {
        guard isCommentsEnabled,
              let count = contentProvider.commentCount()?.intValue,
              count > 0 else {
            return nil
        }
        return WPStyleGuide.commentCountForDisplay(count)
    }

    var likeCount: String? {
        guard isLikesEnabled,
              let count = contentProvider.likeCount()?.intValue,
              count > 0 else {
            return nil
        }
        return WPStyleGuide.likeCountForDisplay(count)
    }

    var postCounts: String? {
        let countStrings = [likeCount, commentCount].compactMap { $0 }
        return countStrings.count > 0 ? countStrings.joined(separator: " • ") : nil
    }

    private var readerPost: ReaderPost? {
        contentProvider as? ReaderPost
    }

    var isPostLiked: Bool {
        contentProvider.isLiked()
    }

    var isAvatarEnabled: Bool {
        guard let post = contentProvider as? ReaderPost else {
            return false
        }
        return post.isP2Type() && contentProvider.avatarURLForDisplay() != nil
    }

    var isSiteIconEnabled: Bool {
        siteIconURL != nil
    }

    var isReblogEnabled: Bool {
        !contentProvider.isPrivate() && actionVisibility.isEnabled
    }

    var isFeaturedImageEnabled: Bool {
        contentProvider.featuredImageURLForDisplay?() != nil
    }

    var isCommentsEnabled: Bool {
        let usesWPComAPI = contentProvider.isWPCom() || contentProvider.isJetpack()
        let commentCount = contentProvider.commentCount()?.intValue ?? 0
        let hasComments = commentCount > 0

        return usesWPComAPI && (contentProvider.commentsOpen() || hasComments)
    }

    var isLikesEnabled: Bool {
        let likeCount = contentProvider.likeCount()?.intValue ?? 0
        return !contentProvider.isExternal() && (likeCount > 0 || actionVisibility.isEnabled)
    }

    private let contentProvider: ReaderPostContentProvider
    private let actionVisibility: ReaderActionsVisibility
    private weak var parentViewController: ReaderStreamViewController?

    private var followCommentsService: FollowCommentsService?

    private(set) var showsSeparator: Bool

    init(contentProvider: ReaderPostContentProvider,
         isLoggedIn: Bool,
         showsSeparator: Bool = true,
         parentViewController: ReaderStreamViewController) {
        self.contentProvider = contentProvider
        self.actionVisibility = .visible(enabled: isLoggedIn)
        self.showsSeparator = showsSeparator
        self.parentViewController = parentViewController
    }

    // MARK: - Functions

    func downloadAvatarIcon(for imageView: UIImageView) {
        guard let url = contentProvider.avatarURLForDisplay() else {
            return
        }
        downloadImage(for: url, imageView: imageView)
    }

    func downloadSiteIcon(for imageView: UIImageView) {
        guard let url = siteIconURL else {
            return
        }
        downloadImage(for: url, imageView: imageView)
    }

    private func downloadImage(for url: URL, imageView: UIImageView) {
        let mediaRequestAuthenticator = MediaRequestAuthenticator()
        let host = MediaHost(with: contentProvider, failure: { error in
            DDLogError("ReaderPostCardCellViewModel MediaHost error: \(error.localizedDescription)")
        })
        Task {
            do {
                let request = try await mediaRequestAuthenticator.authenticatedRequest(for: url, host: host)
                await imageView.downloadImage(usingRequest: request)
            } catch {
                DDLogError(error)
            }
        }
    }

    func downloadFeaturedImage(with imageLoader: ImageLoader, size: CGSize) {
        guard let url = contentProvider.featuredImageURLForDisplay?() else {
            return
        }
        let imageSize = featuredImageIdealSize ?? size
        let host = MediaHost(with: contentProvider, failure: { error in
            DDLogError(error)
        })
        imageLoader.loadImage(with: url, from: host, preferredSize: imageSize)
    }

    func showSiteDetails() {
        guard let readerPost, let parentViewController else {
            return
        }
        ReaderHeaderAction().execute(post: readerPost, origin: parentViewController)
    }

    func reblog() {
        guard let readerPost, let parentViewController else {
            return
        }
        ReaderReblogAction().execute(readerPost: readerPost, origin: parentViewController, reblogSource: .list)
    }

    func comment(with cell: UITableViewCell) {
        guard let readerPost, let parentViewController else {
            return
        }

        if let indexPath = parentViewController.tableView.indexPath(for: cell),
           let topic = parentViewController.readerTopic,
           ReaderHelpers.topicIsDiscover(topic),
           parentViewController.shouldShowCommentSpotlight {
            parentViewController.reloadReaderDiscoverNudgeFlow(at: indexPath)
        }

        ReaderCommentAction().execute(post: readerPost, origin: parentViewController, source: .postCard)
    }

    func toggleLike(with cell: ReaderPostCardCell) {
        guard let readerPost else {
            return
        }

        ReaderLikeAction().execute(with: readerPost)
    }

    mutating func showMore(with anchor: UIView) {
        guard let readerPost,
              let parentViewController,
              let followCommentsService = FollowCommentsService(post: readerPost) else {
            return
        }
        self.followCommentsService = followCommentsService

        ReaderMenuAction(logged: actionVisibility.isEnabled).execute(
            post: readerPost,
            context: parentViewController.viewContext,
            readerTopic: parentViewController.readerTopic,
            anchor: anchor,
            vc: parentViewController,
            source: ReaderPostMenuSource.card,
            followCommentsService: followCommentsService
        )
        WPAnalytics.trackReader(.postCardMoreTapped)
    }

}
