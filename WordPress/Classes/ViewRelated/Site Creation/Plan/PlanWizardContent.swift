import UIKit

final class PlanWizardContent: WebKitViewController {
    typealias PlanId = Int
    typealias DomainName = String
    typealias PlanSelectionCallback = (PlanId?, DomainName?) -> Void

    private let viewModel: PlanWizardContentViewModel
    private let completion: PlanSelectionCallback

    init(viewModel: PlanWizardContentViewModel, completion: @escaping PlanSelectionCallback) {
        self.viewModel = viewModel
        self.completion = completion
        let configuration = WebViewControllerConfiguration(url: viewModel.url)
        configuration.authenticateWithDefaultAccount()
        configuration.secureInteraction = true
        configuration.displayStatusInNavigationBar = false
        super.init(configuration: configuration)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
    }

    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if viewModel.isPlanSelected(url) {
            completion(viewModel.selectedPlanId(from: url), viewModel.selectedDomainName(from: url))
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    // MARK: - Required Init

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
