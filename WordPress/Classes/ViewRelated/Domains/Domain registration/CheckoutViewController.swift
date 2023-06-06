import UIKit

struct CheckoutViewModel {
    let url: URL
}

final class CheckoutViewController: WebKitViewController {
    typealias PurchaseCallback = ((CheckoutViewController) -> Void)

    let viewModel: CheckoutViewModel
    let purchaseCallback: PurchaseCallback?

    private var webViewURLChangeObservation: NSKeyValueObservation?

    init(viewModel: CheckoutViewModel, purchaseCallback: PurchaseCallback?) {
        self.viewModel = viewModel
        self.purchaseCallback = purchaseCallback

        let configuration = WebViewControllerConfiguration(url: viewModel.url)
        configuration.authenticateWithDefaultAccount()
        configuration.secureInteraction = true
        super.init(configuration: configuration)
    }

    // MARK: - Required Init

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observePurchase()
    }

    private func observePurchase() {
        webViewURLChangeObservation = webView.observe(\.url, options: .new) { [weak self] _, change in
            guard let self = self,
                  let newURL = change.newValue as? URL else {
                return
            }

            if newURL.absoluteString.hasPrefix("\(Environment.current.wordPressComURL)checkout/thank-you") {
                self.purchaseCallback?(self)

                /// Stay on Checkout page
                self.webView.goBack()
                self.webViewURLChangeObservation = nil
            }
        }
    }
}
