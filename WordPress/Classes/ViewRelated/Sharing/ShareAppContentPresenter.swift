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

    private var account: WPAccount

    private lazy var remote: ShareAppContentServiceRemote = {
        ShareAppContentServiceRemote(wordPressComRestApi: account.wordPressComRestV2Api)
    }()

    /// In-memory cache. As long as the same presenter instance is used, there's no need to re-fetch the content everytime `shareContent` is called.
    private var cachedContent: RemoteShareAppContent? = nil

    // MARK: Initialization

    init(account: WPAccount) {
        self.account = account
    }

    // MARK: Public Methods

    /// Fetches the content needed for sharing, and presents the share sheet through the provided `sender` instance.
    ///
    func present(for appName: ShareAppName, in sender: UIViewController, completion: (() -> Void)? = nil) {
        if let content = cachedContent {
            presentShareSheet(with: content, in: sender)
            completion?()
            return
        }

        isLoading = true

        remote.getContent(for: appName) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let content):
                self.cachedContent = content
                self.presentShareSheet(with: content, in: sender)

            case .failure:
                self.showFailureNotice(in: sender)
            }

            self.isLoading = false
            completion?()
        }
    }
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
    func presentShareSheet(with content: RemoteShareAppContent, in viewController: UIViewController) {
        guard let linkURL = content.linkURL() else {
            return
        }

        let activityItems = [
            ShareAppTextActivityItemSource(message: content.message) as Any,
            linkURL as Any
        ]

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        viewController.present(activityViewController, animated: true, completion: nil)
    }

    /// Shows a notice indicating that the share intent failed.
    ///
    func showFailureNotice(in viewController: UIViewController) {
        viewController.displayNotice(title: .failureNoticeText, message: nil)
    }
}

// MARK: Localized Strings

private extension String {
    static let failureNoticeText = NSLocalizedString("Something went wrong. Please try again.",
                                                     comment: "Error message shown when user tries to share the app with others, "
                                                        + "but failed due to unknown errors.")
}
