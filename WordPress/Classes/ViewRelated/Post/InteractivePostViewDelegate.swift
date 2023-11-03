import Foundation

protocol InteractivePostViewDelegate: AnyObject {
    func edit(_ post: AbstractPost)
    func view(_ post: AbstractPost)
    func stats(for post: AbstractPost)
    func duplicate(_ post: AbstractPost)
    func publish(_ post: AbstractPost)
    func trash(_ post: AbstractPost, completion: @escaping () -> Void)
    func draft(_ post: AbstractPost)
    func retry(_ post: AbstractPost)
    func cancelAutoUpload(_ post: AbstractPost)
    func share(_ post: AbstractPost, fromView view: UIView)
    func blaze(_ post: AbstractPost)
    func comments(_ post: AbstractPost)
    func setParent(for post: AbstractPost)
    func setHomepage(for post: AbstractPost)
    func setPostsPage(for post: AbstractPost)
}

extension InteractivePostViewDelegate {
    func setParent(for post: AbstractPost) {}
    func setHomepage(for post: AbstractPost) {}
    func setPostsPage(for post: AbstractPost) {}

    func trash(_ post: AbstractPost) {
        self.trash(post, completion: {})
    }
}
