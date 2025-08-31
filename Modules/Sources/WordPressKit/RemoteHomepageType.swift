import Foundation

/// The type of homepage used by a site: blog posts (.posts), or static pages (.page).
public enum RemoteHomepageType {
    case page
    case posts

    /// True if the site uses a page for its front page, rather than blog posts
    internal var isPageOnFront: Bool {
        return self == .page
    }
}
