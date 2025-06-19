import UIKit
import SwiftUI
import WordPressUI
import WordPressKit

final class ActivityLogsViewController: UIHostingController<AnyView> {
    private let viewModel: ActivityLogsViewModel

    init(blog: Blog) {
        self.viewModel = ActivityLogsViewModel(blog: blog)
        super.init(rootView: AnyView(ActivityLogsView(viewModel: viewModel)))
        self.title = Strings.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Strings {
    static let title = NSLocalizedString("activity.logs.title", value: "Activity", comment: "Title for the activity logs screen")
}
