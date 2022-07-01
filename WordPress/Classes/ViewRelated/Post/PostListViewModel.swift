import Foundation

protocol PostListViewModelOutputs {
    var editingPostUploadFailed: (() -> Void)? { get set }
    var editingPostUploadSuccess: ((Post) -> Void)? { get set }
    var statsConfigured: ((Int, String?, URL?) -> Void)? { get set }
}

/// Convert to protocol if more inputs are needed.
typealias PostListViewModelInputs = InteractivePostViewDelegate

typealias PostListViewModelType = PostListViewModelInputs & PostListViewModelOutputs

/// REFACTOR IN PROGRESS: Extracting VM logic from `PostListViewController`
final class PostListViewModel: PostListViewModelInputs, PostListViewModelOutputs {
    private enum Constants {
        enum AnalyticsProperty: String {
            case type
            case filter
        }
    }

    // MARK: - Output Closures
    var editingPostUploadFailed: (() -> Void)?
    var editingPostUploadSuccess: ((Post) -> Void)?
    var statsConfigured: ((Int, String?, URL?) -> Void)?

    // MARK: - Internal State
    lazy var filterSettings: PostListFilterSettings = {
        return PostListFilterSettings(blog: self.blog, postType: PostServiceType.post)
    }()

    // MARK: - Private State
    private let blog: Blog
    private let postCoordinator: PostCoordinator
    private let reachabilityUtility: PostListReachabilityProvider

    // MARK: - Lifecycle
    init(
        blog: Blog,
        postCoordinator: PostCoordinator,
        reachabilityUtility: PostListReachabilityProvider = PostListReachabilityUtility()
    ) {
        self.blog = blog
        self.postCoordinator = postCoordinator
        self.reachabilityUtility = reachabilityUtility
    }

    // MARK: - Outputs
    func edit(_ post: AbstractPost) {
        guard let post = post as? Post else {
            return
        }
        guard !postCoordinator.isUploading(post: post) else {
            editingPostUploadFailed?()
            return
        }

        // DI Analytics & test
        WPAppAnalytics.track(.postListEditAction, withProperties: propertiesForAnalytics(), with: post)
        editingPostUploadSuccess?(post)
    }

    func view(_ post: AbstractPost) {

    }

    func stats(for post: AbstractPost) {
        reachabilityUtility.performActionIfConnectionAvailable {
            viewStatsForPost(post)
        }
    }

    private func viewStatsForPost(_ apost: AbstractPost) {
        // Check the blog
        let blog = apost.blog

        guard blog.supports(.stats) else {
            // Needs Jetpack.
            return
        }

        WPAnalytics.track(.postListStatsAction, withProperties: propertiesForAnalytics())

        // Push the Post Stats ViewController
        guard let postID = apost.postID as? Int else {
            return
        }

        SiteStatsInformation.sharedInstance.siteTimeZone = blog.timeZone
        SiteStatsInformation.sharedInstance.oauth2Token = blog.authToken
        SiteStatsInformation.sharedInstance.siteID = blog.dotComID

        guard let permaLink = apost.permaLink else {
            return
        }
        let postURL = URL(string: permaLink as String)
        statsConfigured?(postID, apost.titleForDisplay(), postURL)
    }

    func duplicate(_ post: AbstractPost) {

    }

    func publish(_ post: AbstractPost) {

    }

    func trash(_ post: AbstractPost) {

    }

    func restore(_ post: AbstractPost) {

    }

    func draft(_ post: AbstractPost) {

    }

    func retry(_ post: AbstractPost) {

    }

    func cancelAutoUpload(_ post: AbstractPost) {

    }

    func share(_ post: AbstractPost, fromView view: UIView) {

    }

    func copyLink(_ post: AbstractPost) {

    }
}

private extension PostListViewModel {
    func propertiesForAnalytics() -> [String: AnyObject] {
        var properties = [String: AnyObject]()

        properties[Constants.AnalyticsProperty.type.rawValue] = PostServiceType.post as AnyObject?
        properties[Constants.AnalyticsProperty.filter.rawValue] = filterSettings.currentPostListFilter().title as AnyObject?

        if let dotComID = blog.dotComID {
            properties[WPAppAnalyticsKeyBlogID] = dotComID
        }

        return properties
    }
}
