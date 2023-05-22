import UIKit

struct PlanSelectionViewModel {

    let blog: Blog
    let url: URL

    init?(blog: Blog) {
        self.blog = blog

        guard let homeUrl = blog.homeURL, let siteUrl = URL(string: homeUrl as String), let host = siteUrl.host else {
            return nil
        }

        var components = URLComponents(string: Constants.plansWebAddress)!

        components.queryItems = [
            URLQueryItem(name: Constants.domainAndPlanPackageParameter, value: "true"),
            URLQueryItem(name: Constants.jetpackAppPlansParameter, value: "true")
        ]

        components.path += "/" + host
        guard let url = components.url else { return nil }
        self.url = url
    }

    enum Constants {
        static let plansWebAddress = "https://wordpress.com/plans/yearly"
        static let domainAndPlanPackageParameter = "domainAndPlanPackage"
        static let jetpackAppPlansParameter = "jetpackAppPlans"
    }
}

final class PlanSelectionViewController: WebKitViewController {
    let viewModel: PlanSelectionViewModel

    init(viewModel: PlanSelectionViewModel) {
        self.viewModel = viewModel

        let configuration = WebViewControllerConfiguration(url: viewModel.url)
        configuration.authenticateWithDefaultAccount()
        configuration.secureInteraction = true
        super.init(configuration: configuration)
    }

    // MARK: - Required Init

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
