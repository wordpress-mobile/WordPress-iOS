import Foundation
import WordPressShared

/// `PostListFilterSettings` manages settings for filtering posts (by author or status)
/// - Note: previously found within `AbstractPostListViewController`
class PostListFilterSettings: NSObject {
    fileprivate static let currentPostAuthorFilterKey = "CurrentPostAuthorFilterKey"
    fileprivate static let currentPageListStatusFilterKey = "CurrentPageListStatusFilterKey"
    fileprivate static let currentPostListStatusFilterKey = "CurrentPostListStatusFilterKey"

    let blog: Blog
    let postType: PostServiceType
    fileprivate var allPostListFilters: [PostListFilter]?

    enum AuthorFilter: UInt {
        case mine = 0
        case everyone = 1
    }
    /// Initializes a new PostListFilterSettings instance
    /// - Parameter blog: the blog which owns the list of posts
    /// - Parameter postType: the type of post being listed
    init(blog: Blog, postType: PostServiceType) {
        self.blog = blog
        self.postType = postType
    }

    func availablePostListFilters() -> [PostListFilter] {

        if allPostListFilters == nil {
            allPostListFilters = PostListFilter.postListFilters()
        }

        return allPostListFilters!
    }

    func filterThatDisplaysPostsWithStatus(_ postStatus: BasePost.Status) -> PostListFilter {
        let index = indexOfFilterThatDisplaysPostsWithStatus(postStatus)
        return availablePostListFilters()[index]
    }

    func indexOfFilterThatDisplaysPostsWithStatus(_ postStatus: BasePost.Status) -> Int {
        var index = 0
        var found = false

        for (idx, filter) in availablePostListFilters().enumerated() {
            if filter.statuses.contains(postStatus) {
                found = true
                index = idx
                break
            }
        }

        if !found {
            // The draft filter is the catch all by convention.
            index = indexForFilterWithType(.draft)
        }

        return index
    }

    func indexForFilterWithType(_ filterType: PostListFilter.Status) -> Int {
        if let index = availablePostListFilters().index(where: { (filter: PostListFilter) -> Bool in
            return filter.filterType == filterType
        }) {
            return index
        } else {
            return NSNotFound
        }
    }

    func setFilterWithPostStatus(_ status: BasePost.Status) {
        let index = indexOfFilterThatDisplaysPostsWithStatus(status)
        self.setCurrentFilterIndex(index)

    }

    // MARK: - Current filter

    /// - returns: the last active PostListFilter
    func currentPostListFilter() -> PostListFilter {
        return availablePostListFilters()[currentFilterIndex()]
    }

    func keyForCurrentListStatusFilter() -> String {
        switch postType {
        case .page:
            return type(of: self).currentPageListStatusFilterKey
        case .post:
            return type(of: self).currentPageListStatusFilterKey
        default:
            return ""
        }
    }

    /// currentPostListFilter: returns the index of the last active PostListFilter
    func currentFilterIndex() -> Int {

        let userDefaults = UserDefaults.standard

        if let filter = userDefaults.object(forKey: keyForCurrentListStatusFilter()) as? Int, filter < availablePostListFilters().count {

            return filter
        } else {
            return 0 // first item is the default
        }
    }

    /// setCurrentFilterIndex: stores the index of the last active PostListFilter
    func setCurrentFilterIndex(_ newIndex: Int) {
        let index = self.currentFilterIndex()

        guard newIndex != index else {
            return
        }

        UserDefaults.standard.set(newIndex, forKey: self.keyForCurrentListStatusFilter())
        UserDefaults.resetStandardUserDefaults()
    }

    // MARK: - Author-related methods

    func canFilterByAuthor() -> Bool {
        if postType == .post {
            return blog.isMultiAuthor && blog.userID != nil
        }
        return false
    }

    func authorIDFilter() -> NSNumber? {
        return currentPostAuthorFilter() == .mine ? blog.userID : nil
    }

    func shouldShowOnlyMyPosts() -> Bool {
        let filter = currentPostAuthorFilter()
        return filter == .mine
    }

    /// currentPostListFilter: returns the last active AuthorFilter
    func currentPostAuthorFilter() -> AuthorFilter {
        if !canFilterByAuthor() {
            return .everyone
        }

        if let filter = UserDefaults.standard.object(forKey: type(of: self).currentPostAuthorFilterKey) {
            if (filter as AnyObject).uintValue == AuthorFilter.everyone.rawValue {
                return .everyone
            }
        }

        return .mine
    }

    /// currentPostListFilter: stores the last active AuthorFilter
    /// - Note: _Also tracks a .PostListAuthorFilterChanged analytics event_
    func setCurrentPostAuthorFilter(_ filter: AuthorFilter) {
        guard filter != currentPostAuthorFilter() else {
            return
        }

        WPAnalytics.track(.postListAuthorFilterChanged, withProperties: propertiesForAnalytics())

        UserDefaults.standard.set(filter.rawValue, forKey: type(of: self).currentPostAuthorFilterKey)
        UserDefaults.resetStandardUserDefaults()
    }

    // MARK: - Analytics

    func propertiesForAnalytics() -> [String: AnyObject] {
        var properties = [String: AnyObject]()

        properties["type"] = postType.rawValue as AnyObject?
        properties["filter"] = currentPostListFilter().title as AnyObject?

        if let dotComID = blog.dotComID {
            properties[WPAppAnalyticsKeyBlogID] = dotComID
        }

        return properties
    }
}
