import Foundation
import SwiftUI
import WordPressCore
import WordPressShared

struct ApplicationPasswordRequiredView<Content: View>: View {
    private let blog: Blog
    private let localizedFeatureName: String
    @State private var site: WordPressSite?
    private let builder: (WordPressClient) -> Content

    weak var presentingViewController: UIViewController?

    init(blog: Blog, localizedFeatureName: String, presentingViewController: UIViewController, @ViewBuilder content: @escaping (WordPressClient) -> Content) {
        wpAssert(blog.account == nil, "The Blog argument should be a self-hosted site")

        self.blog = blog
        self.localizedFeatureName = localizedFeatureName
        self.site = try? WordPressSite(blog: blog)
        self.presentingViewController = presentingViewController
        self.builder = content
    }

    var body: some View {
        if let site {
            builder(WordPressClient(site: site))
        } else {
            RestApiUpgradePrompt(localizedFeatureName: localizedFeatureName) {
                Task {
                    await self.migrate()
                }
            }
        }
    }

    @MainActor
    private func migrate() async {
        guard let presenter = presentingViewController else { return }

        guard let url = try? blog.getUrlString() else {
            Notice(title: Strings.siteUrlNotFoundError).post()
            return
        }

        do {
            // Get an application password for the given site.
            let authenticator = SelfHostedSiteAuthenticator()
            let blogID = try await authenticator.signIn(site: url, from: presenter, context: .reauthentication(TaggedManagedObjectID(blog), username: blog.username))

            // Modify the `site` variable to display the intended feature.
            let blog = try ContextManager.shared.mainContext.existingObject(with: blogID)
            self.site = try .init(blog: blog)
        } catch {
            Notice(error: error).post()
        }
    }

    enum Strings {
        static var siteUrlNotFoundError: String {
            NSLocalizedString("applicationPasswordMigration.error.siteUrlNotFound", value: "Cannot find the current site's url", comment: "Error message when the current site's url cannot be found")
        }

        static func userNameMismatch(expected: String) -> String {
            let format = NSLocalizedString("applicationPasswordMigration.error.usernameMismatch", value: "You need to sign in with user \"%@\"", comment: "Error message when the username does not match the signed-in user. The first argument is the currently signed in user's user login name")
            return String(format: format, expected)
        }
    }
}
