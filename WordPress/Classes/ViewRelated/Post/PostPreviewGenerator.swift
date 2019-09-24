import Foundation
import AutomatticTracks

@objc
protocol PostPreviewGeneratorDelegate {
    func preview(_ generator: PostPreviewGenerator, attemptRequest request: URLRequest)
    func preview(_ generator: PostPreviewGenerator, loadHTML html: String)
    func previewFailed(_ generator: PostPreviewGenerator, message: String)
}

class PostPreviewGenerator: NSObject {
    @objc let post: AbstractPost
    @objc var previewURL: URL?
    @objc weak var delegate: PostPreviewGeneratorDelegate?
    fileprivate let authenticator: WebViewAuthenticator?

    @objc init(post: AbstractPost) {
        self.post = post
        authenticator = WebViewAuthenticator(blog: post.blog)
        super.init()
    }

    @objc convenience init(post: AbstractPost, previewURL: URL) {
        self.init(post: post)
        self.previewURL = previewURL
    }

    @objc func generate() {
        if let previewURL = previewURL {
            attemptPreview(url: previewURL)
        } else {
            guard let url = post.permaLink.flatMap(URL.init(string:)) else {
                previewRequestFailed(reason: "preview failed because post permalink is unexpectedly nil")
                return
            }
             attemptPreview(url: url)
        }
    }

    @objc func previewRequestFailed(reason: String) {
        delegate?.previewFailed(self, message: NSLocalizedString("There has been an error while trying to reach your site.", comment: "An error message."))
    }

    @objc func interceptRedirect(request: URLRequest) -> URLRequest? {
        return authenticator?.interceptRedirect(request: request)
    }
}


// MARK: - Authentication

private extension PostPreviewGenerator {
    func attemptPreview(url: URL) {

        // Attempt to append params. If that fails, fall back to the original url.
        let url = url.appendingHideMasterbarParameters() ?? url

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
        case .draft, .publishPrivate, .pending, .scheduled, .publish:
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
                previewRequestFailed(reason: "preview failed because url with nonce is unexpectedly nil")
                return
        }
        let request = URLRequest(url: authenticatedUrl)
        delegate?.preview(self, attemptRequest: request)
    }

    func attemptCookieAuthenticatedRequest(url: URL) {
        guard let authenticator = authenticator else {
            previewRequestFailed(reason: "preview failed because authenticator is unexpectedly nil")
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
}
