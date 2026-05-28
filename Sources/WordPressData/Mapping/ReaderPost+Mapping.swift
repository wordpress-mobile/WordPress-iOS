import CoreData
import WordPressKit
import WordPressShared

extension ReaderPost {
    /// Finds an existing `ReaderPost` matching the given `globalID` and `topic`,
    /// or creates a new one.
    ///
    /// - Returns: A tuple of the post and whether it already existed.
    static func findOrCreate(
        globalID: String?,
        topic: ReaderAbstractTopic?,
        in context: NSManagedObjectContext
    ) -> (post: ReaderPost, isExisting: Bool) {
        if let globalID, let post = context.firstObject(ofType: ReaderPost.self, matching: NSPredicate(
            format: "globalID = %@ AND (topic = %@ OR topic = NULL)",
            globalID, topic ?? NSNull()
        )) {
            return (post, true)
        }
        let post = context.insertNewObject(ofType: ReaderPost.self)
        return (post, false)
    }

    /// Finds or creates a `ReaderPost` and updates it from a `RemoteReaderPost`.
    @objc(createOrUpdateWithRemotePost:topic:context:)
    public static func createOrUpdate(
        with remotePost: RemoteReaderPost,
        topic: ReaderAbstractTopic?,
        context: NSManagedObjectContext
    ) -> ReaderPost {
        let globalID: String? = remotePost.globalID
        let (post, isExisting) = findOrCreate(globalID: globalID, topic: topic, in: context)
        post.update(with: remotePost, isExisting: isExisting, topic: topic, in: context)
        return post
    }

    /// Updates the receiver with values from a `RemoteReaderPost`.
    func update(
        with remotePost: RemoteReaderPost,
        isExisting: Bool,
        topic: ReaderAbstractTopic?,
        in context: NSManagedObjectContext
    ) {
        authorID = remotePost.authorID
        author = remotePost.author
        authorAvatarURL = remotePost.authorAvatarURL
        authorDisplayName = remotePost.authorDisplayName
        authorEmail = remotePost.authorEmail
        authorURL = remotePost.authorURL
        if let organizationID = remotePost.organizationID {
            self.organizationID = organizationID
        }
        siteIconURL = remotePost.siteIconURL
        blogName = remotePost.blogName
        blogDescription = remotePost.blogDescription
        blogURL = remotePost.blogURL
        commentCount = remotePost.commentCount
        commentsOpen = remotePost.commentsOpen
        date_created_gmt = Date.dateFromServerDate(remotePost.date_created_gmt ?? "")
        featuredImage = remotePost.featuredImage
        feedID = remotePost.feedID
        feedItemID = remotePost.feedItemID
        globalID = remotePost.globalID
        isBlogAtomic = remotePost.isBlogAtomic
        isBlogPrivate = remotePost.isBlogPrivate
        isFollowing = remotePost.isFollowing
        isLiked = remotePost.isLiked
        isReblogged = remotePost.isReblogged
        useExcerpt = remotePost.useExcerpt
        isWPCom = remotePost.isWPCom
        likeCount = remotePost.likeCount
        permaLink = remotePost.permalink
        postID = remotePost.postID
        postTitle = remotePost.postTitle
        railcar = remotePost.railcar
        score = remotePost.score
        siteID = remotePost.siteID
        sortDate = remotePost.sortDate
        isSeen = remotePost.isSeen
        isSeenSupported = remotePost.isSeenSupported
        isSubscribedComments = remotePost.isSubscribedComments
        canSubscribeComments = remotePost.canSubscribeComments
        receivesCommentNotifications = remotePost.receivesCommentNotifications

        // The `read/search` endpoint might return the same post on more than one
        // page. If this happens, preserve the original sortRank to avoid content
        // jumping around in the UI.
        if !(isExisting && topic is ReaderSearchTopic), let sortRank = remotePost.sortRank {
            self.sortRank = sortRank
        }

        statusString = remotePost.status
        summary = remotePost.summary
        tags = remotePost.tags
        isSharingEnabled = remotePost.isSharingEnabled
        isLikesEnabled = remotePost.isLikesEnabled
        isSiteBlocked = false

        updateCrossPostMeta(from: remotePost, in: context)
        updatePrimaryTag(from: remotePost, topic: topic)

        isExternal = remotePost.isExternal
        isJetpack = remotePost.isJetpack
        wordCount = remotePost.wordCount
        readingTime = remotePost.readingTime

        updateSourceAttribution(from: remotePost, in: context)

        content = RichContentFormatter.removeInlineStyles(
            RichContentFormatter.removeForbiddenTags(remotePost.content ?? "")
        )

        self.topic = topic
        pathForDisplayImage = remotePost.autoSuggestedFeaturedImage
    }
}

// MARK: - Private

private extension ReaderPost {
    func updateCrossPostMeta(from remotePost: RemoteReaderPost, in context: NSManagedObjectContext) {
        guard let remoteMeta = remotePost.crossPostMeta else {
            crossPostMeta = nil
            return
        }
        let meta = crossPostMeta ?? context.insertNewObject(ofType: ReaderCrossPostMeta.self)
        meta.siteURL = remoteMeta.siteURL ?? ""
        meta.postURL = remoteMeta.postURL ?? ""
        meta.commentURL = remoteMeta.commentURL ?? ""
        meta.siteID = remoteMeta.siteID ?? 0
        meta.postID = remoteMeta.postID ?? 0
        crossPostMeta = meta
    }

    func updatePrimaryTag(from remotePost: RemoteReaderPost, topic: ReaderAbstractTopic?) {
        var tag = remotePost.primaryTag
        var slug = remotePost.primaryTagSlug
        if let tagTopic = topic as? ReaderTagTopic,
           tagTopic.slug == remotePost.primaryTagSlug {
            tag = remotePost.secondaryTag
            slug = remotePost.secondaryTagSlug
        }
        primaryTag = tag
        primaryTagSlug = slug
    }

    func updateSourceAttribution(from remotePost: RemoteReaderPost, in context: NSManagedObjectContext) {
        guard let remote = remotePost.sourceAttribution else {
            sourceAttribution = nil
            return
        }
        let attribution = sourceAttribution ?? context.insertNewObject(ofType: SourcePostAttribution.self)

        attribution.authorName = remote.authorName
        attribution.authorURL = remote.authorURL
        attribution.avatarURL = remote.avatarURL
        attribution.blogName = remote.blogName
        attribution.blogURL = remote.blogURL
        attribution.permalink = remote.permalink
        attribution.blogID = remote.blogID
        attribution.postID = remote.postID
        attribution.commentCount = remote.commentCount
        attribution.likeCount = remote.likeCount
        attribution.attributionType = Self.attributionType(from: remote.taxonomies)
        sourceAttribution = attribution
    }

    static func attributionType(from taxonomies: [Any]?) -> String? {
        guard let taxonomies = taxonomies as? [String] else { return nil }
        if taxonomies.contains("site-pick") {
            return SourcePostAttribution.site
        }
        if taxonomies.contains("image-pick")
            || taxonomies.contains("quote-pick")
            || taxonomies.contains("standard-pick") {
            return SourcePostAttribution.post
        }
        return nil
    }
}
