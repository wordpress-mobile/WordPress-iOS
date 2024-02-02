import SwiftUI

struct SiteMetricsView: View {
    let blog: Blog

    var body: some View {
        if let configuration {
            WebKitView(configuration: configuration)
        } else {
            Image(systemName: "questionmark.app")
                .font(.title)
                .foregroundStyle(Color.secondary)
        }
    }

    private var configuration: WebViewControllerConfiguration? {
        guard let siteID = blog.dotComID?.intValue else {
            return nil // Should never happen
        }
        let url = URL(string: "https://wordpress.com/site-monitoring/\(siteID)")
        let configuration = WebViewControllerConfiguration(url: url)
        configuration.authenticate(blog: blog)
        return configuration
    }
}
