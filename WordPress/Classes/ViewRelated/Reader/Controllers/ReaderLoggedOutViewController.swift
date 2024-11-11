import UIKit
import SwiftUI
import WordPressUI

final class ReaderLoggedOutViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let stateView = UIHostingView(view: EmptyStateView {
            Label(Strings.title, systemImage: "person.crop.circle.badge.plus")
        } description: {
            Text(Strings.details)
        } actions: {
            Button(Strings.signIn) { [weak self] in
                self?.buttonSignInTapped()
            }.buttonStyle(.primary)
        })

        view.addSubview(stateView)
        stateView.pinEdges()
    }

    private func buttonSignInTapped() {
        Task {
            await WordPressDotComAuthenticator().signIn(from: self, context: .default)
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("reader.loggedOut.title", value: "Join the conversation", comment: "Reader logged-out screen title")
    static let details = NSLocalizedString("reader.loggedOut.details", value: "Sign in with a WordPress.com account to follow your favorite blogs", comment: "Reader logged-out screen details")
    static let signIn = NSLocalizedString("reader.loggedOut.signIn", value: "Sign In", comment: "Reader logged-out screen sign in button")
}
