import Foundation

protocol BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?)
    var row: Int { get set }
}

extension BlogDashboardCardConfigurable where Self: UIView {
    var row: Int {
        get {
            return tag
        }
        set {
           tag = newValue
        }
    }
}
