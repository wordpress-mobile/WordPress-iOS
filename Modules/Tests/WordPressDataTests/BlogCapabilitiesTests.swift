import CoreData
import Testing

@testable import WordPressData

@MainActor
struct BlogCapabilitiesTests {
    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    @Test("backup and scan capabilities without self-serve features stay hidden")
    func capabilitiesWithoutSelfServeFeatures() {
        // Personal and Premium WordPress.com plans grant the backup and scan
        // capabilities because WordPress.com backs up and scans those sites
        // internally, but neither has a user-facing UI on those plans.
        let blog = BlogBuilder(mainContext)
            .with(capabilities: ["backup": true, "backup-daily": true, "scan": true])
            .with(planActiveFeatures: ["backups", "backups-daily", "scan", "scan-managed"])
            .build()

        #expect(!blog.isBackupsAllowed())
        #expect(!blog.isScanAllowed())
    }

    @Test("backup capability with backups-self-serve enables backups")
    func backupCapabilityWithSelfServeFeature() {
        let blog = BlogBuilder(mainContext)
            .with(capabilities: ["backup": true])
            .with(planActiveFeatures: ["backups", "backups-self-serve"])
            .build()

        #expect(blog.isBackupsAllowed())
    }

    @Test("a Jetpack Scan product site keeps scan without backups-self-serve")
    func scanProductOnlySite() {
        // A site with only a Jetpack Scan product has a working scan screen,
        // so scan must be gated on scan-self-serve, not backups-self-serve.
        let blog = BlogBuilder(mainContext)
            .with(capabilities: ["scan": true])
            .with(planActiveFeatures: ["scan", "scan-self-serve"])
            .build()

        #expect(blog.isScanAllowed())
        #expect(!blog.isBackupsAllowed())
    }

    @Test("plan features without the capabilities are not enough")
    func featuresWithoutCapabilities() {
        let blog = BlogBuilder(mainContext)
            .with(capabilities: [:])
            .with(planActiveFeatures: ["backups-self-serve", "scan-self-serve"])
            .build()

        #expect(!blog.isBackupsAllowed())
        #expect(!blog.isScanAllowed())
    }
}
