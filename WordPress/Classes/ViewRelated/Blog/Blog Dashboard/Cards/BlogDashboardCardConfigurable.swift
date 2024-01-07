import Foundation

protocol BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, model: DashboardCardModel)
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?)
    func configure(blog: Blog, viewController: BlogDashboardViewController?, model: DashboardDynamicCardModel)
    var row: Int { get set }
}

extension BlogDashboardCardConfigurable {
    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, model: DashboardDynamicCardModel) {
    }

    func configure(blog: Blog, viewController: BlogDashboardViewController?, model: DashboardCardModel) {
        switch model {
        case .normal(let model):
            self.configure(blog: blog, viewController: viewController, apiResponse: model.apiResponse)
        case .dynamic(let model):
            self.configure(blog: blog, viewController: viewController, model: model)
        }
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
