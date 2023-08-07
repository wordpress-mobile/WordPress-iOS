import WebKit

final class SupportChatBotViewController: WebKitViewController {
    private let viewModel: SupportChartBotViewModel

    init(viewModel: SupportChartBotViewModel) {
        self.viewModel = viewModel
        let configuration = WebViewControllerConfiguration(url: viewModel.url)
        configuration.secureInteraction = true
        super.init(configuration: configuration)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript(createDocsBotInitCode(), completionHandler: { (result, error) in
            if let error = error {
                DDLogError("Failed to initialize docs bot code: \(error)")
            }
        })
    }

    /// Creating DocsBotAI JavaScript code so we could tweak configuration from within Swift code
    /// https://docsbot.ai/docs/embeddable-chat-widget
    private func createDocsBotInitCode() -> String {
        """
        (function() {
            DocsBotAI.init({
                id: '\(viewModel.id)',
                options: {
                    horizontalMargin: 40,
                    verticalMargin: 60,
                },
            })
        })();
        """
    }
}
