import Foundation

protocol PostListViewModelProtocol {
    
}

/// REFACTOR IN PROGRESS: Extracting VM logic from `PostListViewController`
final class PostListViewModel: InteractivePostViewDelegate {
    private enum Constants {
        enum AnalyticsProperty: String {
            case type
            case filter
        }
    }

    private let blog: Blog

    init(blog: Blog) {
        self.blog = blog
    }

    lazy var filterSettings: PostListFilterSettings = {
        return PostListFilterSettings(blog: self.blog, postType: PostServiceType.post)
    }()

    func edit(_ post: AbstractPost) {
        guard let post = post as? Post else {
            return
        }
//        guard !PostCoordinator.shared.isUploading(post: post) else {
//            presentAlertForPostBeingUploaded()
//            return
//        }

        WPAppAnalytics.track(.postListEditAction, withProperties: propertiesForAnalytics(), with: post)
//        PostListEditorPresenter.handle(post: post, in: self, entryPoint: .postsList)
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
