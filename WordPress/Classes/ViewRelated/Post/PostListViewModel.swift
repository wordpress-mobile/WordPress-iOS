import Foundation

protocol PostListViewModelOutputs {
    var editingPostUploadFailed: (() -> Void)? { get set }
    var editingPostUploadSuccess: (() -> Void)? { get set }
}

/// Convert to protocol if more inputs are needed.
typealias PostListViewModelInputs = InteractivePostViewDelegate

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
    var editingPostUploadSuccess: (() -> Void)?

    // MARK: - Internal State
    lazy var filterSettings: PostListFilterSettings = {
        return PostListFilterSettings(blog: self.blog, postType: PostServiceType.post)
    }()

    // MARK: - Private State
    private let blog: Blog
    private let postCoordinator: PostCoordinator

    // MARK: - Lifecycle
    init(blog: Blog, postCoordinator: PostCoordinator) {
        self.blog = blog
        self.postCoordinator = postCoordinator
    }

    // MARK: - Outputs
    func edit(_ post: AbstractPost) {
        guard let post = post as? Post else {
            return
        }
        guard !postCoordinator.isUploading(post: post) else {
//            presentAlertForPostBeingUploaded()
            editingPostUploadFailed?()
            return
        }

        WPAppAnalytics.track(.postListEditAction, withProperties: propertiesForAnalytics(), with: post)
//        PostListEditorPresenter.handle(post: post, in: self, entryPoint: .postsList)
        editingPostUploadSuccess?()
    }

    func view(_ post: AbstractPost) {

    }

    func stats(for post: AbstractPost) {

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
