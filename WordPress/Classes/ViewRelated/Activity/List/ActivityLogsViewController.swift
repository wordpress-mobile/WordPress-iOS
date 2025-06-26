import UIKit
import SwiftUI
import WordPressUI
import WordPressKit

final class ActivityLogsViewController: UIHostingController<ActivityLogsView> {
    private let viewModel: ActivityLogsViewModel

    init(blog: Blog) {
        self.viewModel = ActivityLogsViewModel(blog: blog)
        super.init(rootView: ActivityLogsView(viewModel: viewModel))
        self.title = Strings.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Strings {
    static let title = NSLocalizedString("activityLogs.title", value: "Activity", comment: "Title for the activity logs screen")
}
