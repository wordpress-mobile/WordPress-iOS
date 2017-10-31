import Foundation

@objc
protocol PostPreviewGeneratorDelegate {
    func preview(_ generator: PostPreviewGenerator, attemptRequest request: URLRequest)
    func preview(_ generator: PostPreviewGenerator, loadHTML html: String)
}

class PostPreviewGenerator: NSObject {
    let post: AbstractPost
    weak var delegate: PostPreviewGeneratorDelegate?

    init(post: AbstractPost) {
        self.post = post
        super.init()
    }

    func generate() {
        guard let url = post.permaLink.flatMap(URL.init(string:)),
            !post.hasLocalChanges() else {
                showFakePreview()
                return
        }

        guard WordPressAppDelegate.sharedInstance().connectionAvailable else {
            showFakePreview(message:
                NSLocalizedString("The internet connection appears to be offline.", comment: "") +
                    " " +
                NSLocalizedString("A simple preview is shown below.", comment: "")
            )
            return
        }

        attemptPreview(url: url)
    }

    func previewRequestFailed(error: NSError) {
        showFakePreview(message:
            NSLocalizedString("There has been an error while trying to reach your site.", comment: "") +
                " " +
                NSLocalizedString("A simple preview is shown below.", comment: "")
        )
    }
}


// MARK: - Authentication

private extension PostPreviewGenerator {
    func attemptPreview(url: URL) {
        switch authenticationRequired {
        case .nonce:
            attemptNonceAuthenticatedRequest(url: url)
        case .cookie:
            attemptCookieAuthenticatedRequest(url: url)
        case .none:
            attemptUnauthenticatedRequest(url: url)
        }
    }

    var authenticationRequired: Authentication {
        guard needsLogin() else {
            return .none
        }
        if post.blog.supports(.noncePreviews) {
            return .nonce
        } else {
            return .cookie
        }
    }

    enum Authentication {
        case nonce
        case cookie
        case none
    }

    func needsLogin() -> Bool {
        guard let status = post.status else {
            assertionFailure("A post should always have a status")
            return false
        }
        switch status {
        case .draft, .publishPrivate, .pending, .scheduled:
            return true
        default:
            return post.blog.isPrivate()
        }
    }

    func attemptUnauthenticatedRequest(url: URL) {
        let request = URLRequest(url: url)
        delegate?.preview(self, attemptRequest: request)
    }

    func attemptNonceAuthenticatedRequest(url: URL) {
        guard let nonce = post.blog.getOptionValue("frame_nonce") as? String,
            let authenticatedUrl = addNonce(nonce, to: url) else {
                showFakePreview()
                return
        }
        let request = URLRequest(url: authenticatedUrl)
        delegate?.preview(self, attemptRequest: request)
    }

    func attemptCookieAuthenticatedRequest(url: URL) {
        guard let authenticator = WebViewAuthenticator(blog: post.blog) else {
            showFakePreview()
            return
        }
        authenticator.request(url: url, cookieJar: HTTPCookieStorage.shared, completion: { [weak delegate] request in
            delegate?.preview(self, attemptRequest: request)
        })
    }
}

private extension PostPreviewGenerator {
    func addNonce(_ nonce: String, to url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "preview", value: "true"))
        queryItems.append(URLQueryItem(name: "frame-nonce", value: nonce))
        components.queryItems = queryItems
        return components.url
    }

    func showFakePreview(message: String? = nil) {
        let builder = FakePreviewBuilder(apost: post, message: message)
        delegate?.preview(self, loadHTML: builder.build())
    }
}
