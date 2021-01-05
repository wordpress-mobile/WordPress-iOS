import Foundation

@objc protocol InteractivePostViewDelegate {
    func edit(_ post: AbstractPost)
    func view(_ post: AbstractPost)
    func stats(for post: AbstractPost)
    func duplicate(_ post: AbstractPost)
    func publish(_ post: AbstractPost)
    func trash(_ post: AbstractPost)
    func restore(_ post: AbstractPost)
    func draft(_ post: AbstractPost)
    func retry(_ post: AbstractPost)
    func cancelAutoUpload(_ post: AbstractPost)
    func share(_ post: AbstractPost, fromView view: UIView)
}
