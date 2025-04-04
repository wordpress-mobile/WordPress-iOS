import WordPressKit

extension Blog {

    /// Returns a REST API client, if available
    ///
    /// If the blog is a WordPress.com one or it has Jetpack it will return a REST API client.
    /// Otherwise, the XML-RPC API should be used.
    ///
    /// - Warning: this method doesn't know if a Jetpack blog has the JSON API disabled.
    @objc
    public var wordPressComRestApi: WordPressComRestApi? {
        // FIXME: We are banking on the fact that by the time a consumer reads this, WPAccount will already have initialized its API client instance.
        account?._private_wordPressComRestApi
    }

    /// Whether the blog is hosted on WordPress.com or connected through Jetpack.
    @objc
    public func isAccessibleThroughWPCom() -> Bool {
        wordPressComRestApi != nil
    }
}
