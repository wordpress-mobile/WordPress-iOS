import UIKit
import CoreData
import WordPressData
import WordPressKit
import WordPressShared
import SwiftUI

final class NewPostSettingsViewController: UIHostingController<PostSettingsView> {
    private let viewModel: PostSettingsViewModel

    /// Shows a "Post Settings" screen that can be used outside of the "Post Editor".
    ///
    /// - note: Creates a revisions for editing automatically.
    static func showStandaloneEditor(for post: AbstractPost, from presentingVC: UIViewController) {
        let revision = post.createRevision()
        let viewModel = PostSettingsViewModel(post: revision)
        let postSettingsVC = NewPostSettingsViewController(viewModel: viewModel)
        let navigation = UINavigationController(rootViewController: postSettingsVC)
        presentingVC.present(navigation, animated: true)
    }

    init(viewModel: PostSettingsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: PostSettingsView(viewModel: viewModel))
    }

    @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct PostSettingsView: View {
    @ObservedObject var viewModel: PostSettingsViewModel

    var body: some View {
        Text("Post Settings View")
    }
}
