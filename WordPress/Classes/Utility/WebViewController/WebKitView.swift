import SwiftUI

struct WebKitView: UIViewControllerRepresentable {
    let configuration: WebViewControllerConfiguration

    func makeUIViewController(context: Context) -> WebKitViewController {
        WebKitViewController(configuration: configuration)
    }

    func updateUIViewController(_ uiViewController: WebKitViewController, context: Context) {
        // Do nothing
    }
}
