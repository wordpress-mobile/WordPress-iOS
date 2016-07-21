import Foundation

@objc class PostListFilterSettings: NSObject {
    private static let currentPostAuthorFilterKey = "CurrentPostAuthorFilterKey"
    private static let currentPageListStatusFilterKey = "CurrentPageListStatusFilterKey"
    private static let currentPostListStatusFilterKey = "CurrentPostListStatusFilterKey"

    let blog:Blog
    let postType:PostServiceType
    private var allPostListFilters:[PostListFilter]?

    enum AuthorFilter : UInt {
        case Mine = 0
        case Everyone = 1
    }

    init(blog:Blog, postType:PostServiceType) {
        self.blog = blog
        self.postType = postType
    }

    func canFilterByAuthor() -> Bool {
        if postType == .Post
        {
            return blog.isHostedAtWPcom && blog.isMultiAuthor && blog.account?.userID != nil
        }
        return false
    }

    func authorIDFilter() -> NSNumber? {
        return currentPostAuthorFilter() == .Mine ? blog.account?.userID : nil
    }

    func shouldShowOnlyMyPosts() -> Bool {
        let filter = currentPostAuthorFilter()
        return filter == .Mine
    }

    func currentPostAuthorFilter() -> AuthorFilter {
        if !canFilterByAuthor() {
            return .Everyone
        }

        if let filter = NSUserDefaults.standardUserDefaults().objectForKey(self.dynamicType.currentPostAuthorFilterKey) {
            if filter.unsignedIntegerValue == AuthorFilter.Everyone.rawValue {
                return .Everyone
            }
        }

        return .Mine
    }

    func setCurrentPostAuthorFilter(filter: AuthorFilter) {
        guard filter != currentPostAuthorFilter() else {
            return
        }

        NSUserDefaults.standardUserDefaults().setObject(filter.rawValue, forKey: self.dynamicType.currentPostAuthorFilterKey)
        NSUserDefaults.resetStandardUserDefaults()
    }

    func availablePostListFilters() -> [PostListFilter] {

        if allPostListFilters == nil {
            allPostListFilters = PostListFilter.postListFilters()
        }

        return allPostListFilters!
    }

    func currentPostListFilter() -> PostListFilter {
        return availablePostListFilters()[currentFilterIndex()]
    }

    func filterThatDisplaysPostsWithStatus(postStatus: String) -> PostListFilter {
        let index = indexOfFilterThatDisplaysPostsWithStatus(postStatus)
        return availablePostListFilters()[index]
    }

    func indexOfFilterThatDisplaysPostsWithStatus(postStatus: String) -> Int {
        var index = 0
        var found = false

        for (idx, filter) in availablePostListFilters().enumerate() {
            if filter.statuses.contains(postStatus) {
                found = true
                index = idx
                break
            }
        }

        if !found {
            // The draft filter is the catch all by convention.
            index = indexForFilterWithType(.Draft)
        }

        return index
    }

    func indexForFilterWithType(filterType: PostListFilter.Status) -> Int {
        if let index = availablePostListFilters().indexOf({ (filter: PostListFilter) -> Bool in
            return filter.filterType == filterType
        }) {
            return index
        } else {
            return NSNotFound
        }
    }

    func keyForCurrentListStatusFilter() -> String {
        switch postType {
        case .Page:
            return self.dynamicType.currentPageListStatusFilterKey
        case .Post:
            return self.dynamicType.currentPageListStatusFilterKey
        default:
            return ""
        }
    }

    func currentFilterIndex() -> Int {

        let userDefaults = NSUserDefaults.standardUserDefaults()

        if let filter = userDefaults.objectForKey(keyForCurrentListStatusFilter()) as? Int
            where filter < availablePostListFilters().count {

            return filter
        } else {
            return 0 // first item is the default
        }
    }

    func setCurrentFilterIndex(newIndex: Int) {
        let index = self.currentFilterIndex()

        guard newIndex != index else {
            return
        }

        NSUserDefaults.standardUserDefaults().setObject(newIndex, forKey: self.keyForCurrentListStatusFilter())
        NSUserDefaults.resetStandardUserDefaults()
    }

    func setFilterWithPostStatus(status: String) {
        let index = indexOfFilterThatDisplaysPostsWithStatus(status)
        self.setCurrentFilterIndex(index)

    }
}
