struct PreviewNonceHandler {
    static func nonceURL(post: AbstractPost, previewURL: URL?) -> URL? {
        let permalink = post.permaLink.flatMap(URL.init(string:))
        guard let url = previewURL ?? permalink else {
            return nil
        }

        if post.blog.supports(.noncePreviews), let nonce = post.blog.getOptionValue("frame_nonce") as? String {
            return addNonce(nonce, to: url)
        } else {
            return url
        }
    }

    private static func addNonce(_ nonce: String, to url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "preview", value: "true"))
        queryItems.append(URLQueryItem(name: "frame-nonce", value: nonce))
        components.queryItems = queryItems
        return components.url
    }
}
