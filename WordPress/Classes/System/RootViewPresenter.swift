import Foundation

protocol RootViewPresenter {
    var rootViewController: UIViewController { get }
    func showBlogDetails(for blog: Blog)
}
