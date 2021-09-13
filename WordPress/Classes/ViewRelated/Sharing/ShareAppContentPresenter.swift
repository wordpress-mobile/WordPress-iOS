/// Encapsulates the logic required to fetch, prepare, and present the contents for sharing the app to others.
///
/// The contents for sharing is first fetched from the API, so the share presentation logic is not synchronously executed.
/// Callers are recommended to listen to progress changes by implementing `didUpdateLoadingState(_ loading:)` as this class' delegate.
///
class ShareAppContentPresenter {

    // MARK: Public Properties

    weak var delegate: ShareAppContentPresenterDelegate?

    /// Tracks content fetch state.
    private(set) var isLoading: Bool = false {
        didSet {
            guard isLoading != oldValue else {
                return
            }
            delegate?.didUpdateLoadingState(isLoading)
        }
    }

    // MARK: Private Properties

    /// The API used for fetching the share app link. Anonymous profile is allowed.
    private let api: WordPressComRestApi

    private lazy var remote: ShareAppContentServiceRemote = {
        ShareAppContentServiceRemote(wordPressComRestApi: api)
    }()

    /// In-memory cache. As long as the same presenter instance is used, there's no need to re-fetch the content everytime `shareContent` is called.
    private var cachedContent: RemoteShareAppContent? = nil

    // MARK: Initialization

    /// Instantiates the presenter. When the provided account is nil, the presenter will default to anonymous API.
    init(account: WPAccount? = nil) {
        self.api = account?.wordPressComRestV2Api ?? .anonymousApi(userAgent: WPUserAgent.wordPress(), localeKey: WordPressComRestApi.LocaleKeyV2)
    }

    // MARK: Public Methods

    /// Fetches the content needed for sharing, and presents the share sheet through the provided `sender` instance.
    ///
    /// - Parameters:
    ///   - appName: The name of the app to be shared. Fetched contents will differ depending on the provided value.
    ///   - sender: The view that will be presenting the share sheet.
    ///   - source: Provides tracking context on where the share app feature is engaged from.
    ///   - sourceView: The view to be the anchor for the popover view on iPad.
    ///   - completion: A closure that's invoked after the process completes.
    func present(for appName: ShareAppName, in sender: UIViewController, source: ShareAppEventSource, sourceView: UIView? = nil, completion: (() -> Void)? = nil) {
        let anchorView = sourceView ?? sender.view
        if let content = cachedContent {
            presentShareSheet(with: content, in: sender, sourceView: anchorView)
            trackEngagement(source: source)
            completion?()
            return
        }

        guard !isLoading else {
            completion?()
            return
        }

        isLoading = true

        remote.getContent(for: appName) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let content):
                self.cachedContent = content
                self.presentShareSheet(with: content, in: sender, sourceView: anchorView)
                self.trackEngagement(source: source)

            case .failure:
                self.showFailureNotice(in: sender)
                self.trackContentFetchFailed()
            }

            self.isLoading = false
            completion?()
        }
    }
}

// MARK: - Tracking Source Definition

enum ShareAppEventSource: String {
    // Feature engaged from the Me page.
    case me

    // Feature engaged from the About page.
    case about
}

// MARK: - Delegate Definition

protocol ShareAppContentPresenterDelegate: AnyObject {
    /// Delegate method called everytime the presenter updates its loading state.
    ///
    /// - Parameter loading: The presenter's latest loading state.
    func didUpdateLoadingState(_ loading: Bool)
}

// MARK: - Private Helpers

private extension ShareAppContentPresenter {
    /// Presents the share sheet by using `UIActivityViewController`. Contents to be shared will be constructed from the provided `content`.
    ///
    /// - Parameters:
    ///   - content: The model containing information metadata for the sharing activity.
    ///   - viewController: The view controller that will be presenting the activity.
    ///   - sourceView: The view set to be the anchor for the popover.
    func presentShareSheet(with content: RemoteShareAppContent, in viewController: UIViewController, sourceView: UIView?) {
        guard let linkURL = content.linkURL() else {
            return
        }

        let activityItems = [
            ShareAppTextActivityItemSource(message: content.message) as Any,
            linkURL as Any
        ]

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sourceView
        viewController.present(activityViewController, animated: true, completion: nil)
    }

    /// Shows a notice indicating that the share intent failed.
    ///
    func showFailureNotice(in viewController: UIViewController) {
        viewController.displayNotice(title: .failureNoticeText, message: nil)
    }

    // MARK: Tracking Helpers

    func trackEngagement(source: ShareAppEventSource) {
        WPAnalytics.track(.recommendAppEngaged, properties: [String.sourceParameterKey: source.rawValue])
    }

    func trackContentFetchFailed() {
        WPAnalytics.track(.recommendAppContentFetchFailed)
    }
}

// MARK: Localized Strings

private extension String {
    static let sourceParameterKey = "source"
    static let failureNoticeText = NSLocalizedString("Something went wrong. Please try again.",
                                                     comment: "Error message shown when user tries to share the app with others, "
                                                        + "but failed due to unknown errors.")
}
