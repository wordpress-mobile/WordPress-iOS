import Foundation

protocol InteractivePostViewDelegate: AnyObject {
    func edit(_ post: AbstractPost)
    func view(_ post: AbstractPost)
    func stats(for post: AbstractPost)
    func duplicate(_ post: AbstractPost)
    func publish(_ post: AbstractPost)
    func trash(_ post: AbstractPost)
    func draft(_ post: AbstractPost)
    func retry(_ post: AbstractPost)
    func cancelAutoUpload(_ post: AbstractPost)
    func share(_ post: AbstractPost, fromView view: UIView)
    func copyLink(_ post: AbstractPost)
    func blaze(_ post: AbstractPost)
    func comments(_ post: AbstractPost)
}
