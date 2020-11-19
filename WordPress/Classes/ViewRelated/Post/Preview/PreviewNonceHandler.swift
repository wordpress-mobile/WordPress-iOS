struct PreviewNonceHandler {
    static func nonceURL(post: AbstractPost, previewURL: URL?) -> URL? {
        let permalink = post.permaLink.flatMap(URL.init(string:))
        guard
            let url = previewURL ?? permalink,
            let unmappedURL = unmapURL(post: post, url: url)
        else {
            return nil
        }

        if post.blog.supports(.noncePreviews), let nonce = post.blog.getOptionValue("frame_nonce") as? String {
            return addNonce(nonce, to: unmappedURL)
        } else {
            return unmappedURL
        }
    }

    private static func addNonce(_ nonce: String, to url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "frame-nonce", value: nonce))
        components.queryItems = addPreviewIfNecessary(items: queryItems)
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
        let queryItems = components.queryItems ?? []
        components.queryItems = addPreviewIfNecessary(items: queryItems)
        components.scheme = unmappedSiteURL.scheme
        components.host = unmappedSiteURL.host

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
