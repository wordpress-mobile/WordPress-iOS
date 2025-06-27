import SwiftUI
import WordPressData

@MainActor
struct PostSettingsSocialAccountsView: UIViewControllerRepresentable {
    let blogID: Int
    let model: PrepublishingAutoSharingModel
    weak var delegate: PrepublishingSocialAccountsDelegate?
    let coreDataStack: CoreDataStackSwift

    func makeUIViewController(context: Context) -> PrepublishingSocialAccountsViewController {
        PrepublishingSocialAccountsViewController(
            blogID: blogID,
            model: model,
            delegate: delegate,
            coreDataStack: coreDataStack
        )
    }

    func updateUIViewController(_ uiViewController: PrepublishingSocialAccountsViewController, context: Context) {
        // No updates needed
    }
}
