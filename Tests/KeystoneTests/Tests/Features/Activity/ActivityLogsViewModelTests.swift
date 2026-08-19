import Foundation
import Testing

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("ActivityLogsViewModel Tests")
struct ActivityLogsViewModelTests {
    @Test("sites without backups-self-serve hide the backup and scan activity groups")
    func excludesRewindAndScanWithoutSelfServeBackups() {
        let context = ContextManager.forTesting().mainContext
        // A Personal or Premium WordPress.com plan grants backups but not
        // backups-self-serve, which is what gates the groups on the web.
        let blog = BlogBuilder(context)
            .with(planActiveFeatures: ["backups", "backups-daily", "scan"])
            .build()
        let viewModel = ActivityLogsViewModel(blog: blog)

        #expect(viewModel.excludedActivityGroups == ["rewind", "scan"])
    }

    @Test("sites with backups-self-serve see every activity group")
    func excludesNothingWithSelfServeBackups() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context)
            .with(planActiveFeatures: ["backups", "backups-self-serve", "scan"])
            .build()
        let viewModel = ActivityLogsViewModel(blog: blog)

        #expect(viewModel.excludedActivityGroups.isEmpty)
    }

    @Test("the backup list is never filtered")
    func excludesNothingInBackupMode() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context)
            .with(planActiveFeatures: [])
            .build()
        let viewModel = ActivityLogsViewModel(blog: blog, isBackupMode: true)

        #expect(viewModel.excludedActivityGroups.isEmpty)
    }
}
