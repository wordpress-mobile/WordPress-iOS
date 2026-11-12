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
        account?.wordPressComRestApi
    }

    /// Whether the blog is hosted on WordPress.com or connected through Jetpack.
    public var isAccessibleThroughWPCom: Bool {
        wordPressComRestApi != nil
    }

    /// Whether the blog has no usable remote because its WordPress.com account has no token.
    ///
    /// A blog hosted at WordPress.com, or one without a stored XML-RPC password, can only be reached with the
    /// account's token. Remote factories return no remote for such a blog instead of falling back to Core REST
    /// or XML-RPC with empty credentials. A Jetpack-connected self-hosted blog with a stored password keeps
    /// using XML-RPC.
    ///
    /// Reading this property does not trigger the WordPress.com sign-in, unlike `wordPressComRestApi`.
    @objc public var isMissingRequiredWordPressComToken: Bool {
        guard let account else {
            return false
        }
        if let token = account.authToken, !token.isEmpty {
            return false
        }
        return isHostedAtWPcom || password == nil
    }
}
