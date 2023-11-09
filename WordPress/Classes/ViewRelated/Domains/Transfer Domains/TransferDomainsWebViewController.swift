import Foundation

final class TransferDomainsWebViewController: WebKitViewController {
    
    private enum Constants {
        static let url = URL(string: "https://wordpress.com/transfer-google-domains/")!
    }

    init(source: String? = nil) {
        let configuration = WebViewControllerConfiguration(url: Constants.url)
        configuration.analyticsSource = source
        configuration.authenticateWithDefaultAccount()
        super.init(configuration: configuration)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
