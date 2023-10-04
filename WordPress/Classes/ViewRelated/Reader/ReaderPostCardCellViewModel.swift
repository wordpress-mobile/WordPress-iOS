
struct ReaderPostCardCellViewModel {

    // MARK: - Properties

    var siteIconURL: URL? {
        let scale = WordPressAppDelegate.shared?.window?.screen.scale ?? 1.0
        let size = ReaderPostCardCell.Constants.iconImageSize * scale
        return contentProvider.siteIconForDisplay(ofSize: Int(size))
    }

    var siteTitle: String? {
        if let post = contentProvider as? ReaderPost, post.isP2Type(), let author = contentProvider.authorForDisplay() {
            let strings = [author, contentProvider.blogNameForDisplay?()].compactMap { $0 }
            return strings.joined(separator: " ▸ ")
        }

        return contentProvider.blogNameForDisplay?()
    }

    var postDate: String? {
        guard let dateForDisplay = contentProvider.dateForDisplay()?.toShortString() else {
            return nil
        }
        return siteTitle != nil ? "• \(dateForDisplay)" : dateForDisplay
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

    var postCounts: String? {
        let commentCount = contentProvider.commentCount()?.intValue ?? 0
        let likeCount = contentProvider.likeCount()?.intValue ?? 0
        var countStrings = [String]()

        if isLikesEnabled {
            countStrings.append(WPStyleGuide.likeCountForDisplay(likeCount))
        }

        if isCommentsEnabled {
            countStrings.append(WPStyleGuide.commentCountForDisplay(commentCount))
        }
        return countStrings.count > 0 ? countStrings.joined(separator: " • ") : nil
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

    init(contentProvider: ReaderPostContentProvider, isLoggedIn: Bool) {
        self.contentProvider = contentProvider
        self.actionVisibility = .visible(enabled: isLoggedIn)
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

}
