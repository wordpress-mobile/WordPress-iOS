import UIKit
import Combine
import SwiftUI
import WordPressData
import WordPressShared
import WordPressUI

/// A screen shown just before publishing the post and allows you to change
/// the post settings along with some publishing options like the publish date.
final class PublishPostViewController: UIHostingController<NavigationView<PublishPostView>> {
    init(post: AbstractPost) {
        super.init(rootView: NavigationView { PublishPostView() })
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// TODO: add isStandalone support
// TODO: add `PrepublishingSheetResult`
struct PublishPostView: View {
    var body: some View {
        Text("Here")
    }
}
