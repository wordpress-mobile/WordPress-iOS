import UIKit
import Combine
import SwiftUI
import WordPressData
import WordPressShared
import WordPressUI

/// A screen shown just before publishing the post and allows you to change
/// the post settings along with some publishing options like the publish date.
final class PublishPostViewController: UIHostingController<NavigationView<PublishPostView>> {
    private let settingsViewModel: PostSettingsViewModel

    init(post: AbstractPost) {
        // TODO: add isStandalone support
        let settingsViewModel = PostSettingsViewModel(post: post, isStandalone: true)
        self.settingsViewModel = settingsViewModel
        super.init(rootView: NavigationView { PublishPostView(settingsViewModel: settingsViewModel) })
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// TODO: add `PrepublishingSheetResult`
struct PublishPostView: View {
    @ObservedObject var settingsViewModel: PostSettingsViewModel

    var body: some View {
        Form {
            PostSettingsFormContentView(viewModel: settingsViewModel)
        }
    }
}
