import Foundation

class BlazeCreateCampaignWebViewModel: BlazeWebViewModel {

    // MARK: Public Variables

    var isFlowCompleted = false
    private(set) var currentStep: String = BlazeFlowSteps.undefinedStep

    // MARK: Private Variables

    private let source: BlazeSource
    private let blog: Blog
    private let postID: NSNumber?
    private weak var view: BlazeWebView?
    private let remoteConfigStore: RemoteConfigStore
    private let externalURLHandler: ExternalURLHandler
    private var linkBehavior: LinkBehavior = .all

    // MARK: Initializer

    init(source: BlazeSource,
         blog: Blog,
         postID: NSNumber?,
         view: BlazeWebView,
         remoteConfigStore: RemoteConfigStore = RemoteConfigStore(),
         externalURLHandler: ExternalURLHandler = UIApplication.shared) {
        self.source = source
        self.blog = blog
        self.postID = postID
        self.view = view
        self.remoteConfigStore = remoteConfigStore
        self.externalURLHandler = externalURLHandler
        setLinkBehavior()
    }

    // MARK: Computed Variables

    private var initialURL: URL? {
        guard let siteURL = blog.displayURL else {
            return nil
        }
        var urlString: String
        if let postID {
            urlString = String(format: Constants.blazePostURLFormat, siteURL, postID.intValue, source.description)
        }
        else {
            urlString = String(format: Constants.blazeSiteURLFormat, siteURL, source.description)
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

    var navigationTitle: String {
        return Strings.navigationTitle
    }

    func startBlazeFlow() {
        guard let initialURL,
              let cookieJar = view?.cookieJar else {
            BlazeEventsTracker.trackBlazeFlowError(for: source, currentStep: currentStep)
            view?.dismissView()
            return
        }
        authenticatedRequest(for: initialURL, with: cookieJar) { [weak self] (request) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.view?.load(request: request)
            BlazeEventsTracker.trackBlazeFlowStarted(for: weakSelf.source)
        }
    }

    func dismissTapped() {
        view?.dismissView()
        if isFlowCompleted {
            NotificationCenter.default.post(name: .blazeCampaignCreated, object: nil)
            BlazeEventsTracker.trackBlazeFlowCompleted(for: source, currentStep: currentStep)
        } else {
            BlazeEventsTracker.trackBlazeFlowCanceled(for: source, currentStep: currentStep)
        }
    }

    func shouldNavigate(to request: URLRequest, with type: WKNavigationType) -> WKNavigationActionPolicy {
        currentStep = extractCurrentStep(from: request) ?? currentStep
        updateIsFlowCompleted()
        view?.reloadNavBar()
        return linkBehavior.handle(request: request, with: type, externalURLHandler: externalURLHandler)
    }

    func isCurrentStepDismissible() -> Bool {
        return currentStep != RemoteConfigParameter.blazeNonDismissibleStep.value(using: remoteConfigStore)
    }

    func webViewDidFail(with error: Error) {
        BlazeEventsTracker.trackBlazeFlowError(for: source, currentStep: currentStep)
    }

    // MARK: Helpers

    private func setLinkBehavior() {
        guard let baseURLString else {
            return
        }
        self.linkBehavior = .withBaseURLOnly(baseURLString)
    }

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
        if currentStep == RemoteConfigParameter.blazeFlowCompletedStep.value(using: remoteConfigStore) {
            isFlowCompleted = true // mark flow as completed if completion step is reached
        }
        if currentStep == BlazeFlowSteps.blazeWidgetDefaultStep {
            isFlowCompleted = false // reset flag is user start a new ad creation flow inside the web view
        }
    }
}

extension Foundation.Notification.Name {
    static let blazeCampaignCreated = Foundation.Notification.Name("BlazeWebFlowBlazeCampaignCreated")
}

extension BlazeCreateCampaignWebViewModel: WebKitAuthenticatable {
    var authenticator: RequestAuthenticator? {
        RequestAuthenticator(blog: blog)
    }
}

private extension BlazeCreateCampaignWebViewModel {
    enum Strings {
        static let navigationTitle = NSLocalizedString("feature.blaze.title",
                                                       value: "Blaze",
                                                       comment: "Name of a feature that allows the user to promote their posts.")
    }
    enum Constants {
        static let baseURLFormat = "https://wordpress.com/advertising/%@"
        static let blazeSiteURLFormat = "https://wordpress.com/advertising/%@?source=%@"
        static let blazePostURLFormat = "https://wordpress.com/advertising/%@?blazepress-widget=post-%d&source=%@"
        static let blazeWidgetQueryIdentifier = "blazepress-widget"
        static let blazeCampaignsURLPath = "campaigns"
    }

    enum BlazeFlowSteps {
        static let undefinedStep = "unspecified"
        static let postsListStep = "posts-list"
        static let campaignsListStep = "campaigns-list"
        static let blazeWidgetDefaultStep = "step-1"
    }
}
