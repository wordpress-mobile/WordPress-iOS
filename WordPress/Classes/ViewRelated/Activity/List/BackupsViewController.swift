import UIKit
import SwiftUI
import WordPressUI
import WordPressKit

final class BackupsViewController: UIHostingController<ActivityLogsView> {
    private let viewModel: ActivityLogsViewModel

    init(blog: Blog) {
        self.viewModel = ActivityLogsViewModel(blog: blog, isBackupMode: true)
        super.init(rootView: ActivityLogsView(viewModel: viewModel))
        self.title = Strings.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Strings {
    static let title = NSLocalizedString("backups.title", value: "Backups", comment: "Title for the backups screen")
}
