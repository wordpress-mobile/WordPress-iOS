import Foundation

protocol BlazeWebView {
    func load(request: URLRequest)
    var cookieJar: CookieJar { get }
}

class BlazeWebViewModel {

    // MARK: Private Variables

    private let source: BlazeWebViewCoordinator.Source
    private let blog: Blog
    private let postID: NSNumber?
    private let view: BlazeWebView
    private var currentStep: String = Constants.undefinedStep

    // MARK: Initializer

    init(source: BlazeWebViewCoordinator.Source,
         blog: Blog,
         postID: NSNumber?,
         view: BlazeWebView) {
        self.source = source
        self.blog = blog
        self.postID = postID
        self.view = view
    }

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
        authenticatedRequest(for: initialURL, with: view.cookieJar) { [weak self] (request) in
            self?.view.load(request: request)
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
        currentStep = extractCurrentStep(from: request)
        return .allow
    }

    // MARK: Helpers

    func extractCurrentStep(from request: URLRequest) -> String {
        if let baseURL = initialURL?.absoluteString,
           let url = request.url,
           url.absoluteString.hasPrefix(baseURL),
           let step = url.fragment {
            print("Request Intercepted with URL \(url)")
            print("Step is: \(step)")
            return step
        }
        return Constants.undefinedStep
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
        static let undefinedStep = "undefined"
    }
}
