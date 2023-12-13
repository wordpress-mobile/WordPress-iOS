import Foundation

protocol BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, model: DashboardCardModel)
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?)
    var row: Int { get set }
}

extension BlogDashboardCardConfigurable {

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, model: DashboardCardModel) {
        guard case .default(let model) = model else {
            return
        }
        self.configure(blog: blog, viewController: viewController, apiResponse: model.apiResponse)
    }
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
