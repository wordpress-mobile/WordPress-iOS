import Foundation
import CoreData
import Testing
import WordPressData
@testable import WordPress
@testable import WordPressMediaLibrary

@Suite("MediaTrackerAdapter upload events", .serialized)
@MainActor
struct MediaTrackerAdapterUploadEventsTests {
    let contextManager = ContextManager.forTesting()
    var mainContext: NSManagedObjectContext { contextManager.mainContext }

    private func makeAdapter() -> MediaTrackerAdapter {
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        contextManager.saveContextAndWait(mainContext)
        return MediaTrackerAdapter(blog: blog, baseProperties: ["is_v2": "1"])
    }

    @Test("Photo from PHPicker maps to AddedPhotoViaDeviceLibrary")
    func photoLibraryImage() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .photoLibrary, kind: .image))

        #expect(TestAnalyticsTracker.tracked.last?.stat == .mediaLibraryAddedPhotoViaDeviceLibrary)
    }

    @Test("Video from PHPicker maps to AddedVideoViaDeviceLibrary")
    func photoLibraryVideo() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .photoLibrary, kind: .video))

        #expect(TestAnalyticsTracker.tracked.last?.stat == .mediaLibraryAddedVideoViaDeviceLibrary)
    }

    @Test("Photo from camera maps to AddedPhotoViaCamera")
    func cameraImage() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .camera, kind: .image))

        #expect(TestAnalyticsTracker.tracked.last?.stat == .mediaLibraryAddedPhotoViaCamera)
    }

    @Test("Video from camera maps to AddedVideoViaCamera")
    func cameraVideo() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .camera, kind: .video))

        #expect(TestAnalyticsTracker.tracked.last?.stat == .mediaLibraryAddedVideoViaCamera)
    }

    @Test("Photo from file picker maps to AddedPhotoViaOtherApps")
    func otherAppsImage() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .otherApps, kind: .image))

        #expect(TestAnalyticsTracker.tracked.last?.stat == .mediaLibraryAddedPhotoViaOtherApps)
    }

    @Test("Video from file picker maps to AddedVideoViaOtherApps")
    func otherAppsVideo() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .otherApps, kind: .video))

        #expect(TestAnalyticsTracker.tracked.last?.stat == .mediaLibraryAddedVideoViaOtherApps)
    }

    @Test("Document is silently dropped")
    func documentDropped() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .otherApps, kind: .document))

        #expect(TestAnalyticsTracker.tracked.isEmpty)
    }

    @Test("Audio is silently dropped")
    func audioDropped() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryAdded(source: .photoLibrary, kind: .audio))

        #expect(TestAnalyticsTracker.tracked.isEmpty)
    }

    @Test("Retry maps to mediaLibraryUploadMediaRetried")
    func retryEvent() {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        makeAdapter().track(.mediaLibraryUploadRetried)

        #expect(TestAnalyticsTracker.tracked.last?.stat == .mediaLibraryUploadMediaRetried)
    }
}
