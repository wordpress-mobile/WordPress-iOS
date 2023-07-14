import Foundation

class BlazeCampaignDetailsWebViewModel: BlazeWebViewModel {

    // MARK: Private Variables

    private let source: BlazeSource
    private let blog: Blog
    private let campaignID: Int
    private weak var view: BlazeWebView?
    private let externalURLHandler: ExternalURLHandler
    private var linkBehavior: LinkBehavior = .all

    // MARK: Initializer

    init(source: BlazeSource,
         blog: Blog,
         campaignID: Int,
         view: BlazeWebView,
         externalURLHandler: ExternalURLHandler = UIApplication.shared) {
        self.source = source
        self.blog = blog
        self.campaignID = campaignID
        self.view = view
        self.externalURLHandler = externalURLHandler
        setLinkBehavior()
    }

    // MARK: Computed Variables

    private var initialURL: URL? {
        guard let siteURL = blog.displayURL else {
            return nil
        }
        let urlString = String(format: Constants.campaignDetailsURLFormat, siteURL, campaignID, source.description)
        return URL(string: urlString)
    }

    private var baseURLString: String? {
        guard let siteURL = blog.displayURL else {
            return nil
        }
        return String(format: Constants.baseURLFormat, siteURL)
    }

    // MARK: Public Functions

    var isFlowCompleted: Bool {
        return true
    }

    var navigationTitle: String {
        return Strings.navigationTitle
    }

    func startBlazeFlow() {
        guard let initialURL,
              let cookieJar = view?.cookieJar else {
            BlazeEventsTracker.trackCampaignDetailsError(for: source)
            view?.dismissView()
            return
        }
        authenticatedRequest(for: initialURL, with: cookieJar) { [weak self] (request) in
            guard let self else {
                return
            }
            self.view?.load(request: request)
            BlazeEventsTracker.trackCampaignDetailsOpened(for: self.source)
        }
    }

    func dismissTapped() {
        view?.dismissView()
        BlazeEventsTracker.trackCampaignDetailsDismissed(for: source)
    }

    func shouldNavigate(to request: URLRequest, with type: WKNavigationType) -> WKNavigationActionPolicy {
        return linkBehavior.handle(request: request, with: type, externalURLHandler: externalURLHandler)
    }

    func isCurrentStepDismissible() -> Bool {
        return true
    }

    func webViewDidFail(with error: Error) {
        // TODO: Track Analytics Error Event
    }

    // MARK: Helpers

    private func setLinkBehavior() {
        guard let baseURLString else {
            return
        }
        self.linkBehavior = .withBaseURLOnly(baseURLString)
    }
}

extension BlazeCampaignDetailsWebViewModel: WebKitAuthenticatable {
    var authenticator: RequestAuthenticator? {
        RequestAuthenticator(blog: blog)
    }
}

private extension BlazeCampaignDetailsWebViewModel {
    enum Strings {
        static let navigationTitle = NSLocalizedString("feature.blaze.campaignDetails.title",
                                                       value: "Campaign Details",
                                                       comment: "Title of screen the displays the details of an advertisement campaign.")
    }
    enum Constants {
        // TODO: Replace these constants with remote config params
        static let baseURLFormat = "https://wordpress.com/advertising/%@"
        static let campaignDetailsURLFormat = "https://wordpress.com/advertising/%@/campaigns/%d?source=%@"
    }
}
