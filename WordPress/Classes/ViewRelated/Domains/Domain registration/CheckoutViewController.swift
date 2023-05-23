import UIKit

struct CheckoutViewModel {
    let url: URL
}

final class CheckoutViewController: WebKitViewController {
    let viewModel: CheckoutViewModel

    init(viewModel: CheckoutViewModel) {
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
