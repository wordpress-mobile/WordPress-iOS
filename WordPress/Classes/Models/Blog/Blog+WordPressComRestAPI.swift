import WordPressData
import WordPressKit

public extension Blog {

    /// Returns a REST API client, if available
    ///
    /// If the blog is a WordPress.com one or it has Jetpack it will return a REST API client.
    /// Otherwise, the XML-RPC API should be used.
    ///
    /// - Warning: this method doesn't know if a Jetpack blog has the JSON API disabled.
    @objc
    var wordPressComRestApi: WordPressComRestApi? {
        account?.wordPressComRestApi
    }

    /// Whether the blog is hosted on WordPress.com or connected through Jetpack.
    @objc
    func isAccessibleThroughWPCom() -> Bool {
        wordPressComRestApi != nil
    }
}
