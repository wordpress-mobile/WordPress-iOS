import Foundation

protocol BlazeWebView {
    func load(request: URLRequest)
    func reloadNavBar()
    var cookieJar: CookieJar { get }
}

class BlazeWebViewModel {

    // MARK: Public Variables

    var isFlowCompleted = false

    // MARK: Private Variables

    private let source: BlazeWebViewCoordinator.Source
    private let blog: Blog
    private let postID: NSNumber?
    private let view: BlazeWebView
    private var currentStep: String = BlazeFlowSteps.undefinedStep
    private let remoteConfig = RemoteConfig()

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

    private var baseURLString: String? {
        guard let siteURL = blog.displayURL else {
            return nil
        }
        return String(format: Constants.baseURLFormat, siteURL)
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

    func dismissTapped() {
        // TODO: To be implemented
        // Track event
    }

    func shouldNavigate(request: URLRequest) -> WebNavigationPolicy {
        // TODO: To be implemented
        // Use this to track the current step and take actions accordingly
        // We should also block unknown urls
        currentStep = extractCurrentStep(from: request) ?? currentStep
        updateIsFlowCompleted()
        view.reloadNavBar()
        return .allow
    }

    func isCurrentStepDismissible() -> Bool {
        let nonDismissibleSteps = remoteConfig.blazeNonDismissibleSteps.value ?? []
        return !nonDismissibleSteps.contains(currentStep)
    }

    // MARK: Helpers

    private func extractCurrentStep(from request: URLRequest) -> String? {
        guard let url = request.url,
              let baseURLString,
              url.absoluteString.hasPrefix(baseURLString) else {
            return nil
        }
        if let query = url.query, query.contains(Constants.blazeWidgetQueryIdentifier) {
            if let step = url.fragment {
                return step
            }
            else {
                return BlazeFlowSteps.blazeWidgetDefaultStep
            }
        }
        else {
            if let lastPathComponent = url.pathComponents.last, lastPathComponent == Constants.blazeCampaignsURLPath {
                return BlazeFlowSteps.campaignsListStep
            }
            else {
                return BlazeFlowSteps.postsListStep
            }
        }
    }

    private func updateIsFlowCompleted() {
        if currentStep == remoteConfig.blazeFlowCompletedStep.value {
            isFlowCompleted = true // mark flow as completed if completion step is reached
        }
        if currentStep == BlazeFlowSteps.blazeWidgetDefaultStep {
            isFlowCompleted = false // reset flag is user start a new ad creation flow inside the web view
        }
    }
}

extension BlazeWebViewModel: WebKitAuthenticatable {
    var authenticator: RequestAuthenticator? {
        RequestAuthenticator(blog: blog)
    }
}

private extension BlazeWebViewModel {
    enum Constants {
        static let baseURLFormat = "https://wordpress.com/advertising/%@"
        static let blazeSiteURLFormat = "https://wordpress.com/advertising/%@?source=%@"
        static let blazePostURLFormat = "https://wordpress.com/advertising/%@?blazepress-widget=post-%d&source=%@"
        static let blazeWidgetQueryIdentifier = "blazepress-widget"
        static let blazeCampaignsURLPath = "campaigns"
    }

    enum BlazeFlowSteps {
        static let undefinedStep = "undefined"
        static let postsListStep = "posts_list"
        static let campaignsListStep = "campaigns_list"
        static let blazeWidgetDefaultStep = "step_1"
    }
}
