import Testing
import WordPressData
import WordPressMediaLibrary
@testable import WordPress

@MainActor
struct MediaLibraryRoutingExternalSourcesTests {

    @Test func dotComBlog_jetpackEnabled_offersStockPhotos() {
        let context = ContextManager.forTesting().mainContext
        let blog = ModelTestHelper.insertDotComBlog(context: context)
        // `blog.wordPressComRestApi` is non-nil only when the account has a
        // non-empty authToken (WPAccount+RestApi.swift:13-24). The default
        // fixture leaves authToken empty, so set one before asserting.
        blog.account?.authToken = "test-token"
        try? context.save()
        #expect(blog.wordPressComRestApi != nil)

        // Stabilize the Jetpack-features gate. MediaPickerSource.freePhotos
        // resolves to `blog.supports(.stockPhotos) && jetpackFeaturesEnabled()`.
        // If `JetpackFeaturesRemovalCoordinator.currentAppUIType` is nil, the
        // removal-phase fallback can disable Jetpack features and silently
        // hide Stock Photos in this test. Save/restore the override
        // around the test so other suites aren't affected.
        let savedAppUIType = JetpackFeaturesRemovalCoordinator.currentAppUIType
        JetpackFeaturesRemovalCoordinator.currentAppUIType = .normal
        defer { JetpackFeaturesRemovalCoordinator.currentAppUIType = savedAppUIType }

        let options = MediaLibraryRouting.externalPickerOptions(for: blog)
        let ids = options.map(\.id)
        #expect(ids.contains("stockPhotos"))
    }

    @Test func selfHostedBlog_hidesStockPhotos() {
        let blog = ModelTestHelper.insertSelfHostedBlog(context: ContextManager.forTesting().mainContext)
        let options = MediaLibraryRouting.externalPickerOptions(for: blog)
        let ids = options.map(\.id)
        #expect(!ids.contains("stockPhotos")) // V1 parity: gated on .freePhotos
    }
}
