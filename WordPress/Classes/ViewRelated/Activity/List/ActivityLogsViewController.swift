import UIKit
import SwiftUI
import WordPressUI
import WordPressKit

final class ActivityLogsViewController: UIHostingController<AnyView> {
    private let viewModel: ActivityLogsViewModel

    init(blog: Blog, isBackupMode: Bool = false) {
        self.viewModel = ActivityLogsViewModel(blog: blog, isBackupMode: isBackupMode)
        super.init(rootView: AnyView(ActivityLogsView(viewModel: viewModel)))
        self.title = isBackupMode ? Strings.backupsTitle : Strings.activityTitle
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Strings {
    static let activityTitle = NSLocalizedString("activity.logs.title", value: "Activity", comment: "Title for the activity logs screen")
    static let backupsTitle = NSLocalizedString("backups.title", value: "Backups", comment: "Title for the backups screen")
}
