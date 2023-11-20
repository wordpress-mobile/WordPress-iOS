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

    func isPlanSelected(_ redirectionURL: URL) -> Bool {
        return redirectionURL.absoluteString.starts(with: Constants.checkoutWebAddress)
    }

    enum Constants {
        static let plansWebAddress = "https://wordpress.com/plans/yearly"
        static let checkoutWebAddress = "https://wordpress.com/checkout"
        static let domainAndPlanPackageParameter = "domainAndPlanPackage"
        static let jetpackAppPlansParameter = "jetpackAppPlans"
    }
}

final class PlanSelectionViewController: WebKitViewController {
    typealias PlanSelectionCallback = (PlanSelectionViewController, URL) -> Void

    let viewModel: PlanSelectionViewModel
    var planSelectedCallback: PlanSelectionCallback?

    private var webViewURLChangeObservation: NSKeyValueObservation?

    init(viewModel: PlanSelectionViewModel, customTitle: String?, analyticsSource: String? = nil) {
        self.viewModel = viewModel

        let configuration = WebViewControllerConfiguration(url: viewModel.url)
        configuration.authenticateWithDefaultAccount()
        configuration.secureInteraction = true
        configuration.customTitle = customTitle
        configuration.analyticsSource = analyticsSource ?? ""
        super.init(configuration: configuration)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observePlanSelection()
    }

    private func observePlanSelection() {
        webViewURLChangeObservation = webView.observe(\.url, options: .new) { [weak self] _, change in
            guard let self = self,
                  let newURL = change.newValue as? URL else {
                return
            }

            if self.viewModel.isPlanSelected(newURL) {
                self.planSelectedCallback?(self, newURL)

                /// Stay on Plan Selection page
                self.webView.goBack()
                self.webViewURLChangeObservation = nil
            }
        }
    }

    // MARK: - Required Init

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
