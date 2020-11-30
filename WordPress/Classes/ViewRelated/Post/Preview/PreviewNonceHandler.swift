struct PreviewNonceHandler {
    static func nonceURL(post: AbstractPost, previewURL: URL?) -> URL? {
        let permalink = post.permaLink.flatMap(URL.init(string:))
        guard var url = previewURL ?? permalink else {
            return nil
        }

        if shouldComposePreviewURL(post: post) {
            url = addPreviewIfNecessary(url: url) ?? url
            url = unmapURL(post: post, url: url) ?? url
            url = addNonceIfNecessary(post: post, url: url) ?? url
        }

        return url
    }

    private static func addNonceIfNecessary(post: AbstractPost, url: URL) -> URL? {
        guard
            post.blog.supports(.noncePreviews),
            let nonce = post.blog.getOptionValue("frame_nonce") as? String,
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return url
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "frame-nonce", value: nonce))
        components.queryItems = queryItems
        return components.url
    }

    private static func unmapURL(post: AbstractPost, url: URL) -> URL? {
        guard
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let unmappedSite = post.blog.getOptionValue("unmapped_url") as? String,
            let unmappedSiteURL = URL(string: unmappedSite)
        else {
            return url
        }

        components.scheme = unmappedSiteURL.scheme
        components.host = unmappedSiteURL.host

        return components.url
    }

    private static func shouldComposePreviewURL(post: AbstractPost) -> Bool {
        // If the post is not published, add the preview param.
        if post.status!.rawValue != PostStatusPublish {
            return true
        }

        // If the post is published, but has changes, add the preview param.
        if post.hasUnsavedChanges() || post.hasRemoteChanges() {
            return true
        }

        return false
    }

    private static func addPreviewIfNecessary(url: URL) -> URL? {
        guard
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return url
        }
        let queryItems = components.queryItems ?? []
        components.queryItems = addPreviewIfNecessary(items: queryItems)
        return components.url
    }

    private static func addPreviewIfNecessary(items: [URLQueryItem]) -> [URLQueryItem] {
        var queryItems = items
        // Only add the preview query param if it doesn't exist.
        if !(queryItems.map { $0.name }).contains("preview") {
            queryItems.append(URLQueryItem(name: "preview", value: "true"))
        }
        return queryItems
    }

}
