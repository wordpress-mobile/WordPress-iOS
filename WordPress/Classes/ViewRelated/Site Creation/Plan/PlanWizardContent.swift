import UIKit

final class PlanWizardContent: WebKitViewController {
    typealias PlanSelectionCallback = (Int?) -> Void

    private let viewModel: PlanWizardContentViewModel
    private let completion: PlanSelectionCallback

    init(viewModel: PlanWizardContentViewModel, completion: @escaping PlanSelectionCallback) {
        self.viewModel = viewModel
        self.completion = completion
        let configuration = WebViewControllerConfiguration(url: nil)
        configuration.authenticateWithDefaultAccount()
        configuration.secureInteraction = true
        super.init(configuration: configuration)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleView.isHidden = true
        view.backgroundColor = .basicBackground
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        load(request: URLRequest(url: viewModel.url))
    }

    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if viewModel.isPlanSelected(url) {
            completion(viewModel.selectedPlanId(from: url))
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
