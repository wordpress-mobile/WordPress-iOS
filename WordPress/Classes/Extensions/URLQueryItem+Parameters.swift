
extension URLQueryItem {
    /// Query Parameters to be used for the WP Stories feature.
    /// Can be appended to the URL of any WordPress blog post.
    enum WPStory {
        /// Opens the story in fullscreen.
        static let fullscreen = URLQueryItem(name: "wp-story-load-in-fullscreen", value: "true")
        /// Begins playing the story immediately.
        static let playOnLoad = URLQueryItem(name: "wp-story-play-on-load", value: "true")
    }
}
