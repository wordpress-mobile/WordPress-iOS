import Foundation

protocol BlazeWebView {
    func load(request: URLRequest)
    var cookieJar: CookieJar { get }
}

struct BlazeWebViewModel {

    // MARK: Private Variables

    let source: BlazeWebViewCoordinator.Source
    let blog: Blog
    let postID: NSNumber?
    let view: BlazeWebView

    // MARK: Computed Variables

    private var initialURL: URL? {
        guard let siteURL = blog.displayURL else {
            return nil
        }
        var urlString: String
        if let postID {
            urlString = String(format: Constants.blazePostURLFormat, siteURL, postID.intValue, source.rawValue)
        }
        else {
            urlString = String(format: Constants.blazeSiteURLFormat, siteURL, source.rawValue)
        }
        return URL(string: urlString)
    }

    // MARK: Public Functions

    func startBlazeFlow() {
        guard let initialURL else {
            // TODO: Track error & dismiss view
            return
        }
        authenticatedRequest(for: initialURL, with: view.cookieJar) { (request) in
            view.load(request: request)
        }
    }

    func cancelTapped() {
        // TODO: To be implemented
        // Track event
    }

    func shouldNavigate(request: URLRequest) -> WebNavigationPolicy {
        // TODO: To be implemented
        // Use this to track the current step and take actions accordingly
        // We should also block unknown urls
        return .allow
    }
}

extension BlazeWebViewModel: WebKitAuthenticatable {
    var authenticator: RequestAuthenticator? {
        RequestAuthenticator(blog: blog)
    }
}

private extension BlazeWebViewModel {
    enum Constants {
        static let blazeSiteURLFormat = "https://wordpress.com/advertising/%@?source=%@"
        static let blazePostURLFormat = "https://wordpress.com/advertising/%@?blazepress-widget=post-%d&source=%@"
    }
}
