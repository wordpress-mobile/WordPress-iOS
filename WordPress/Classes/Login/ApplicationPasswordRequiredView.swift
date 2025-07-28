import Foundation
import SwiftUI
import WordPressData
import WordPressCore
import WordPressShared
import WordPressUI

struct ApplicationPasswordRequiredView<Content: View>: View {
    private let blog: Blog
    private let localizedFeatureName: String
    @State private var site: WordPressSite?
    @State private var showLoading: Bool = true
    private let builder: (WordPressClient) -> Content

    weak var presentingViewController: UIViewController?

    init(blog: Blog, localizedFeatureName: String, presentingViewController: UIViewController, @ViewBuilder content: @escaping (WordPressClient) -> Content) {
        self.blog = blog
        self.localizedFeatureName = localizedFeatureName
        self.presentingViewController = presentingViewController
        self.builder = content
    }

    var body: some View {
        VStack {
            if blog.isHostedAtWPcom && !blog.isAtomic() {
                EmptyStateView(Strings.unsupported, systemImage: "exclamationmark.triangle.fill")
            } else if showLoading {
                ProgressView()
            } else if let site {
                builder(WordPressClient(site: site))
            } else {
                RestApiUpgradePrompt(localizedFeatureName: localizedFeatureName) {
                    Task {
                        await self.migrate()
                    }
                }
            }
        }
        .task {
            showLoading = true
            defer { showLoading = false }

            updateSite()
            await attemptToCreatePasswordIfNeeded()
        }
    }

    private func attemptToCreatePasswordIfNeeded() async {
        guard self.site == nil else { return }

        do {
            let repository = ApplicationPasswordRepository.shared
            try await repository.createPasswordIfNeeded(for: TaggedManagedObjectID(blog))
            updateSite()
        } catch {
            DDLogError("Failed to create an application password: \(error)")
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
            let _ = try await authenticator.signIn(site: url, from: presenter, context: .reauthentication(TaggedManagedObjectID(blog), username: blog.username))

            // Modify the `site` variable to display the intended feature.
            updateSite()
        } catch {
            Notice(error: error).post()
        }
    }

    private func updateSite() {
        // We check that the site is `selfHosted` to ensure an _Application Password_ is available. That's what this view
        // is for, after all.
        if let site = try? WordPressSite(blog: blog), case .selfHosted = site {
            self.site = site
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

        static var unsupported: String { NSLocalizedString("applicationPasswordMigration.error.unsupported", value: "This site does not support Application Passwords.", comment: "Error message shown when the site doesn't support Application Passwords feature") }
    }
}
