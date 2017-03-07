import Foundation

@objc
protocol PostPreviewGeneratorDelegate {
    func preview(_ generator: PostPreviewGenerator, attemptRequest request: URLRequest)
    func preview(_ generator: PostPreviewGenerator, loadHTML html: String)
}

class PostPreviewGenerator: NSObject {
    let post: AbstractPost
    var delegate: PostPreviewGeneratorDelegate?

    init(post: AbstractPost) {
        self.post = post
        super.init()
    }

    func generate() {
        guard let link = post.permaLink,
            let url = URL(string: link),
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

        if needsLogin() {
            attemptAuthenticatedRequest(url: url)
        } else {
            attemptUnauthenticatedRequest(url: url)
        }
    }

    func previewRequestFailed(error: NSError) {
        showFakePreview(message:
            NSLocalizedString("There has been an error while trying to reach your site.", comment: "") +
                " " +
                NSLocalizedString("A simple preview is shown below.", comment: "")
        )
    }
}

private extension PostPreviewGenerator {
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

    func attemptAuthenticatedRequest(url: URL) {
        let blog = post.blog
        guard let loginURL = URL(string: blog.loginUrl()),
            let username = blog.usernameForSite?.nonEmptyString() else {
                showFakePreview()
                return
        }

        let request: URLRequest
        if blog.supports(.oAuth2Login) {
            guard let token = blog.authToken?.nonEmptyString() else {
                showFakePreview()
                return
            }
            request = WPURLRequest.requestForAuthentication(with: loginURL, redirectURL: url, username: username, password: nil, bearerToken: token, userAgent: nil)
        } else {
            guard let password = blog.password?.nonEmptyString() else {
                showFakePreview()
                return
            }
            request = WPURLRequest.requestForAuthentication(with: loginURL, redirectURL: url, username: username, password: password, bearerToken: nil, userAgent: nil)
        }
        delegate?.preview(self, attemptRequest: request)
    }

    func showFakePreview(message: String? = nil) {
        let builder = FakePreviewBuilder(apost: post, message: message)
        delegate?.preview(self, loadHTML: builder.build())
    }
}
